import request from 'supertest';
import app from '../src/index';

describe('Microservice API Tests', () => {
  
  describe('GET /health', () => {
    it('should return 200 and health status', async () => {
      const res = await request(app).get('/health');
      
      expect(res.status).toBe(200);
      expect(res.body).toHaveProperty('status', 'healthy');
      expect(res.body).toHaveProperty('timestamp');
      expect(res.body).toHaveProperty('uptime');
      expect(res.body).toHaveProperty('version');
    });
    
    it('should return valid timestamp format', async () => {
      const res = await request(app).get('/health');
      
      const timestamp = new Date(res.body.timestamp);
      expect(timestamp).toBeInstanceOf(Date);
      expect(timestamp.toString()).not.toBe('Invalid Date');
    });
    
    it('should return positive uptime', async () => {
      const res = await request(app).get('/health');
      
      expect(res.body.uptime).toBeGreaterThanOrEqual(0);
    });
  });
  
  describe('GET /api/info', () => {
    it('should return 200 and application info', async () => {
      const res = await request(app).get('/api/info');
      
      expect(res.status).toBe(200);
      expect(res.body).toHaveProperty('name');
      expect(res.body).toHaveProperty('version');
      expect(res.body).toHaveProperty('environment');
      expect(res.body).toHaveProperty('uptime');
    });
    
    it('should return valid application metadata', async () => {
      const res = await request(app).get('/api/info');
      
      expect(res.body.name).toBe('Microservice Demo');
      expect(typeof res.body.version).toBe('string');
    });
  });
  
  describe('GET /', () => {
    it('should return 200 and welcome message', async () => {
      const res = await request(app).get('/');
      
      expect(res.status).toBe(200);
      expect(res.body).toHaveProperty('message');
      expect(res.body).toHaveProperty('endpoints');
    });
    
    it('should list available endpoints', async () => {
      const res = await request(app).get('/');
      
      expect(res.body.endpoints).toHaveProperty('health');
      expect(res.body.endpoints).toHaveProperty('info');
      expect(res.body.endpoints).toHaveProperty('calculate');
    });
  });
  
  describe('POST /api/calculate', () => {
    it('should add two numbers correctly', async () => {
      const res = await request(app)
        .post('/api/calculate')
        .send({ operation: 'add', a: 5, b: 3 });
      
      expect(res.status).toBe(200);
      expect(res.body.result).toBe(8);
    });
    
    it('should subtract two numbers correctly', async () => {
      const res = await request(app)
        .post('/api/calculate')
        .send({ operation: 'subtract', a: 10, b: 4 });
      
      expect(res.status).toBe(200);
      expect(res.body.result).toBe(6);
    });
    
    it('should multiply two numbers correctly', async () => {
      const res = await request(app)
        .post('/api/calculate')
        .send({ operation: 'multiply', a: 6, b: 7 });
      
      expect(res.status).toBe(200);
      expect(res.body.result).toBe(42);
    });
    
    it('should divide two numbers correctly', async () => {
      const res = await request(app)
        .post('/api/calculate')
        .send({ operation: 'divide', a: 20, b: 4 });
      
      expect(res.status).toBe(200);
      expect(res.body.result).toBe(5);
    });
    
    it('should return 400 for division by zero', async () => {
      const res = await request(app)
        .post('/api/calculate')
        .send({ operation: 'divide', a: 10, b: 0 });
      
      expect(res.status).toBe(400);
      expect(res.body).toHaveProperty('error', 'Division by zero');
    });
    
    it('should return 400 for invalid operation', async () => {
      const res = await request(app)
        .post('/api/calculate')
        .send({ operation: 'invalid', a: 5, b: 3 });
      
      expect(res.status).toBe(400);
      expect(res.body.error).toContain('Invalid operation');
    });
    
    it('should return 400 for missing fields', async () => {
      const res = await request(app)
        .post('/api/calculate')
        .send({ operation: 'add', a: 5 });
      
      expect(res.status).toBe(400);
      expect(res.body.error).toContain('Missing required fields');
    });
    
    it('should handle zero values', async () => {
      const res = await request(app)
        .post('/api/calculate')
        .send({ operation: 'add', a: 0, b: 0 });
      
      expect(res.status).toBe(200);
      expect(res.body.result).toBe(0);
    });
    
    it('should handle negative numbers', async () => {
      const res = await request(app)
        .post('/api/calculate')
        .send({ operation: 'add', a: -5, b: 3 });
      
      expect(res.status).toBe(200);
      expect(res.body.result).toBe(-2);
    });
  });
  
  describe('404 Handler', () => {
    it('should return 404 for unknown routes', async () => {
      const res = await request(app).get('/unknown');
      
      expect(res.status).toBe(404);
      expect(res.body).toHaveProperty('error', 'Endpoint not found');
      expect(res.body).toHaveProperty('path', '/unknown');
    });
  });
});