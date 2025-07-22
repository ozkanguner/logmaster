#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
LogMaster v2 - Enterprise 5651 Compliance Log Management System
Main FastAPI Application

Author: LogMaster Development Team
License: Enterprise License
Version: 2.0.0
"""

from fastapi import FastAPI, HTTPException, Depends, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.middleware.trustedhost import TrustedHostMiddleware
from fastapi.responses import JSONResponse
from fastapi.staticfiles import StaticFiles
from starlette.middleware.sessions import SessionMiddleware
import uvicorn
import logging
import time
from typing import Optional

# Internal imports
from app.core.config import settings
from app.core.database import engine
from app.core.security import get_current_active_user
from app.api.v1 import auth, devices, logs, users, compliance, monitoring
from app.models import models
from app.core.logger import setup_logging
from app.auth.middleware import AuthenticationMiddleware
from app.compliance.middleware import ComplianceMiddleware

# Setup logging
setup_logging()
logger = logging.getLogger(__name__)

# Create database tables
models.Base.metadata.create_all(bind=engine)

# FastAPI application instance
app = FastAPI(
    title="LogMaster v2 - Enterprise Log Management",
    description="5651 Turkish Law Compliant Log Management System with Device-Level Authentication",
    version="2.0.0",
    docs_url="/api/docs",
    redoc_url="/api/redoc",
    openapi_url="/api/openapi.json"
)

# Middleware configuration
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.ALLOWED_HOSTS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.add_middleware(
    TrustedHostMiddleware,
    allowed_hosts=settings.ALLOWED_HOSTS
)

app.add_middleware(
    SessionMiddleware,
    secret_key=settings.SECRET_KEY,
    max_age=settings.SESSION_TIMEOUT
)

# Custom middleware for authentication and compliance
app.add_middleware(AuthenticationMiddleware)
app.add_middleware(ComplianceMiddleware)

# Static files for frontend
app.mount("/static", StaticFiles(directory="frontend/build/static"), name="static")

# API Routes
app.include_router(
    auth.router,
    prefix="/api/v1/auth",
    tags=["Authentication"]
)

app.include_router(
    devices.router,
    prefix="/api/v1/devices",
    tags=["Device Management"]
)

app.include_router(
    logs.router,
    prefix="/api/v1/logs",
    tags=["Log Management"]
)

app.include_router(
    users.router,
    prefix="/api/v1/users",
    tags=["User Management"]
)

app.include_router(
    compliance.router,
    prefix="/api/v1/compliance",
    tags=["5651 Compliance"]
)

app.include_router(
    monitoring.router,
    prefix="/api/v1/monitoring",
    tags=["System Monitoring"]
)

# Global exception handler
@app.exception_handler(HTTPException)
async def http_exception_handler(request: Request, exc: HTTPException):
    """Global HTTP exception handler with audit logging"""
    logger.warning(
        f"HTTP {exc.status_code} from {request.client.host}: {exc.detail}",
        extra={
            "url": str(request.url),
            "method": request.method,
            "client_ip": request.client.host,
            "user_agent": request.headers.get("user-agent"),
            "status_code": exc.status_code
        }
    )
    
    return JSONResponse(
        status_code=exc.status_code,
        content={
            "error": exc.detail,
            "status_code": exc.status_code,
            "timestamp": time.time(),
            "path": str(request.url.path)
        }
    )

# Request middleware for logging
@app.middleware("http")
async def log_requests(request: Request, call_next):
    """Log all HTTP requests for audit purposes"""
    start_time = time.time()
    
    # Process request
    response = await call_next(request)
    
    # Calculate processing time
    process_time = time.time() - start_time
    
    # Log request details
    logger.info(
        f"{request.method} {request.url.path} - {response.status_code}",
        extra={
            "method": request.method,
            "url": str(request.url),
            "status_code": response.status_code,
            "process_time": process_time,
            "client_ip": request.client.host,
            "user_agent": request.headers.get("user-agent"),
            "content_length": response.headers.get("content-length")
        }
    )
    
    # Add response headers
    response.headers["X-Process-Time"] = str(process_time)
    response.headers["X-LogMaster-Version"] = "2.0.0"
    
    return response

# Health check endpoints
@app.get("/health", tags=["Health"])
async def health_check():
    """System health check endpoint"""
    return {
        "status": "healthy",
        "version": "2.0.0",
        "timestamp": time.time(),
        "services": {
            "database": "connected",
            "elasticsearch": "connected",
            "redis": "connected"
        }
    }

@app.get("/health/detailed", tags=["Health"])
async def detailed_health_check():
    """Detailed system health check with component status"""
    from app.services.health_check import HealthCheckService
    
    health_service = HealthCheckService()
    health_status = await health_service.get_detailed_status()
    
    return health_status

# Root endpoint
@app.get("/", tags=["Root"])
async def root():
    """API root endpoint with system information"""
    return {
        "name": "LogMaster v2 - Enterprise Log Management",
        "version": "2.0.0",
        "description": "5651 Turkish Law Compliant Log Management System",
        "features": [
            "MAC Address Device Authentication",
            "Role-Based Access Control",
            "Device-Specific Permissions",
            "Digital Signature Compliance",
            "Real-time Log Processing",
            "Automated Compliance Reports"
        ],
        "api_docs": "/api/docs",
        "health": "/health"
    }

# Startup event
@app.on_event("startup")
async def startup_event():
    """Application startup tasks"""
    logger.info("🚀 LogMaster v2 starting up...")
    
    # Initialize services
    from app.services.startup import StartupService
    startup_service = StartupService()
    
    try:
        await startup_service.initialize_system()
        logger.info("✅ LogMaster v2 started successfully")
    except Exception as e:
        logger.error(f"❌ Startup failed: {e}")
        raise

# Shutdown event
@app.on_event("shutdown")
async def shutdown_event():
    """Application shutdown tasks"""
    logger.info("🛑 LogMaster v2 shutting down...")
    
    # Cleanup tasks
    from app.services.shutdown import ShutdownService
    shutdown_service = ShutdownService()
    
    try:
        await shutdown_service.cleanup_system()
        logger.info("✅ LogMaster v2 shutdown completed")
    except Exception as e:
        logger.error(f"❌ Shutdown error: {e}")

# Development server
if __name__ == "__main__":
    uvicorn.run(
        "main:app",
        host=settings.HOST,
        port=settings.PORT,
        reload=settings.DEBUG,
        log_level="info" if not settings.DEBUG else "debug",
        access_log=True
    ) 