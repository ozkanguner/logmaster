#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
LogMaster v2 - Database Configuration
PostgreSQL database connection and session management
"""

from sqlalchemy import create_engine, MetaData, event
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker, Session
from sqlalchemy.pool import QueuePool
import logging
from contextlib import contextmanager
from typing import Generator
import time

from app.core.config import settings

logger = logging.getLogger(__name__)

# Database engine with connection pooling
engine = create_engine(
    str(settings.DATABASE_URL),
    poolclass=QueuePool,
    pool_size=settings.DB_POOL_SIZE,
    max_overflow=settings.DB_MAX_OVERFLOW,
    pool_timeout=settings.DB_POOL_TIMEOUT,
    pool_recycle=3600,  # Recycle connections every hour
    pool_pre_ping=True,  # Validate connections before use
    echo=settings.DEBUG,  # Log SQL queries in debug mode
)

# Session factory
SessionLocal = sessionmaker(
    autocommit=False,
    autoflush=False,
    bind=engine
)

# Base class for all models
Base = declarative_base()

# Metadata for database schema
metadata = MetaData()


# Database session dependency
def get_db() -> Generator[Session, None, None]:
    """
    Database session dependency for FastAPI
    Creates a new session for each request and closes it after use
    """
    db = SessionLocal()
    try:
        yield db
    except Exception as e:
        logger.error(f"Database session error: {e}")
        db.rollback()
        raise
    finally:
        db.close()


@contextmanager
def get_db_session() -> Generator[Session, None, None]:
    """
    Context manager for database sessions
    Use for manual database operations outside of FastAPI
    """
    db = SessionLocal()
    try:
        yield db
        db.commit()
    except Exception as e:
        logger.error(f"Database transaction error: {e}")
        db.rollback()
        raise
    finally:
        db.close()


# Database connection events
@event.listens_for(engine, "connect")
def set_sqlite_pragma(dbapi_connection, connection_record):
    """Set database connection parameters on connect"""
    if hasattr(dbapi_connection, 'execute'):
        # Set timezone for PostgreSQL
        try:
            cursor = dbapi_connection.cursor()
            cursor.execute("SET timezone TO 'UTC'")
            cursor.execute("SET statement_timeout = '30s'")
            cursor.close()
        except Exception as e:
            logger.warning(f"Could not set database parameters: {e}")


@event.listens_for(engine, "before_cursor_execute")
def receive_before_cursor_execute(conn, cursor, statement, parameters, context, executemany):
    """Log slow queries for performance monitoring"""
    context._query_start_time = time.time()


@event.listens_for(engine, "after_cursor_execute")
def receive_after_cursor_execute(conn, cursor, statement, parameters, context, executemany):
    """Log query execution time"""
    total = time.time() - context._query_start_time
    if total > 1.0:  # Log queries that take more than 1 second
        logger.warning(f"Slow query detected ({total:.2f}s): {statement[:200]}...")


class DatabaseManager:
    """Database management utilities"""
    
    @staticmethod
    def test_connection() -> bool:
        """Test database connection"""
        try:
            with engine.connect() as connection:
                result = connection.execute("SELECT 1")
                return result.fetchone()[0] == 1
        except Exception as e:
            logger.error(f"Database connection test failed: {e}")
            return False
    
    @staticmethod
    def get_connection_info() -> dict:
        """Get database connection information"""
        try:
            with engine.connect() as connection:
                result = connection.execute("SELECT version()")
                version = result.fetchone()[0]
                
                return {
                    "status": "connected",
                    "version": version,
                    "pool_size": engine.pool.size(),
                    "checked_in": engine.pool.checkedin(),
                    "checked_out": engine.pool.checkedout(),
                    "overflow": engine.pool.overflow(),
                }
        except Exception as e:
            logger.error(f"Could not get database info: {e}")
            return {
                "status": "error",
                "error": str(e)
            }
    
    @staticmethod
    def create_all_tables():
        """Create all database tables"""
        try:
            Base.metadata.create_all(bind=engine)
            logger.info("Database tables created successfully")
        except Exception as e:
            logger.error(f"Error creating database tables: {e}")
            raise
    
    @staticmethod
    def drop_all_tables():
        """Drop all database tables (use with caution!)"""
        try:
            Base.metadata.drop_all(bind=engine)
            logger.warning("All database tables dropped")
        except Exception as e:
            logger.error(f"Error dropping database tables: {e}")
            raise
    
    @staticmethod
    def get_table_list() -> list:
        """Get list of all tables in database"""
        try:
            with engine.connect() as connection:
                result = connection.execute("""
                    SELECT table_name 
                    FROM information_schema.tables 
                    WHERE table_schema = 'public'
                    ORDER BY table_name
                """)
                return [row[0] for row in result.fetchall()]
        except Exception as e:
            logger.error(f"Error getting table list: {e}")
            return []
    
    @staticmethod
    def get_database_size() -> dict:
        """Get database size information"""
        try:
            with engine.connect() as connection:
                # Get database size
                db_size_result = connection.execute(f"""
                    SELECT pg_size_pretty(pg_database_size('{settings.POSTGRES_DB}'))
                """)
                db_size = db_size_result.fetchone()[0]
                
                # Get table sizes
                table_sizes_result = connection.execute("""
                    SELECT 
                        schemaname,
                        tablename,
                        pg_size_pretty(pg_total_relation_size(tablename::text)) as size,
                        pg_total_relation_size(tablename::text) as size_bytes
                    FROM pg_tables 
                    WHERE schemaname = 'public'
                    ORDER BY pg_total_relation_size(tablename::text) DESC
                """)
                
                table_sizes = []
                for row in table_sizes_result.fetchall():
                    table_sizes.append({
                        "schema": row[0],
                        "table": row[1],
                        "size": row[2],
                        "size_bytes": row[3]
                    })
                
                return {
                    "database_size": db_size,
                    "table_sizes": table_sizes
                }
        except Exception as e:
            logger.error(f"Error getting database size: {e}")
            return {"error": str(e)}


# Health check function
async def check_database_health() -> dict:
    """Check database health for monitoring"""
    start_time = time.time()
    
    try:
        db_manager = DatabaseManager()
        connection_test = db_manager.test_connection()
        connection_info = db_manager.get_connection_info()
        
        response_time = time.time() - start_time
        
        return {
            "service": "postgresql",
            "status": "healthy" if connection_test else "unhealthy",
            "response_time": response_time,
            "details": connection_info
        }
    
    except Exception as e:
        response_time = time.time() - start_time
        return {
            "service": "postgresql",
            "status": "unhealthy",
            "response_time": response_time,
            "error": str(e)
        }


# Initialize database manager instance
db_manager = DatabaseManager() 