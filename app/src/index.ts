import express, { Request, Response, ErrorRequestHandler } from 'express';

const app = express();
const PORT: number = parseInt(process.env.PORT ?? '3000', 10);

// Security: Disable X-Powered-By header to avoid disclosing Express version
app.disable('x-powered-by');

// Middleware
app.use(express.json());

// Application metadata
interface AppInfo {
  name: string;
  version: string;
  environment: string;
}

const appInfo: AppInfo = {
  name: 'Microservice Demo',
  version: process.env.npm_package_version ?? '1.0.0',
  environment: process.env.NODE_ENV ?? 'development',
};

// Track uptime
const startTime: number = Date.now();

// Health check endpoint
app.get('/health', (req: Request, res: Response) => {
  const uptime: number = (Date.now() - startTime) / 1000; // time in seconds 
  
  res.status(200).json({
    status: 'healthy',
    timestamp: new Date().toISOString(),
    uptime: uptime,
    version: appInfo.version,
  });
});

// Application info endpoint
app.get('/api/info', (req: Request, res: Response) => {
  res.status(200).json({
    ...appInfo,
    uptime: (Date.now() - startTime) / 1000,
    timestamp: new Date().toISOString(),
  });
});

// Simple calculation endpoint for testing
interface CalculateRequestBody {
  operation: string;
  a: number;
  b: number;
}

app.post('/api/calculate', (req: Request<{}, {}, CalculateRequestBody>, res: Response) => {
  const { operation, a, b } = req.body;
  
  if (!operation || a === undefined || b === undefined) {
    return res.status(400).json({
      error: 'Missing required fields: operation, a, b',
    });
  }
  
  let result: number;
  
  switch (operation) {
    case 'add':
      result = a + b;
      break;
    case 'subtract':
      result = a - b;
      break;
    case 'multiply':
      result = a * b;
      break;
    case 'divide':
      if (b === 0) {
        return res.status(400).json({ error: 'Division by zero' });
      }
      result = a / b;
      break;
    default:
      return res.status(400).json({
        error: 'Invalid operation. Use: add, subtract, multiply, divide',
      });
  }
  
  res.status(200).json({
    operation,
    a,
    b,
    result,
  });
});

// Root endpoint
app.get('/', (req: Request, res: Response) => {
  res.status(200).json({
    message: 'Welcome to the Microservice API',
    endpoints: {
      health: 'GET /health',
      info: 'GET /api/info',
      calculate: 'POST /api/calculate',
    },
  });
});

// 404 handler
app.use((req: Request, res: Response) => {
  res.status(404).json({
    error: 'Endpoint not found',
    path: req.path,
  });
});

// Error handler
const errorHandler: ErrorRequestHandler = (err, req, res, next) => {
  console.error('Error:', err);
  res.status(500).json({
    error: 'Internal server error',
    message: err.message,
  });
};

app.use(errorHandler);

// Start server only if not in test mode
if (process.env.NODE_ENV !== 'test') {
  app.listen(PORT, () => {
    console.log(`The Server is running on port ${PORT}`);
    console.log(`Health check: http://localhost:${PORT}/health`);
  });
}

export default app;