const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const compression = require('compression');
const cookieParser = require('cookie-parser');
const rateLimit = require('express-rate-limit');

const apiRouter = require('./routes');
const apiConfig = require('./config/api');
const errorMiddleware = require('./middleware/error.middleware');
const loggerMiddleware = require('./middleware/logger.middleware');
const swaggerUi = require('swagger-ui-express');
const swaggerDocument = require('./config/swagger.json');

const app = express();

// 1. Helmet (Security headers)
app.use(helmet());

// 2. Compression (Payload compression)
app.use(compression());

// 3. CORS (Cross-origin access control)
app.use(cors());

// Body parsing middlewares
app.use(cookieParser());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// 4. Pino structured request logging
app.use(loggerMiddleware);

// 5. Rate limiting
const limiter = rateLimit({
  windowMs: apiConfig.RATE_LIMIT.WINDOW_MS,
  max: apiConfig.RATE_LIMIT.MAX_REQUESTS,
  message: {
    success: false,
    message: 'Too many requests from this IP, please try again later.',
  },
  standardHeaders: true,
  legacyHeaders: false,
});
app.use('/api', limiter);

// Serve Swagger documentation
app.use('/api/docs', swaggerUi.serve, swaggerUi.setup(swaggerDocument));

// 6. Bind API routes (mounted under /api/v1/ via the routes aggregator)
app.use('/api', apiRouter);

// Base sanity check health endpoint
app.get('/health', (req, res) => {
  res.status(200).json({ status: 'OK', timestamp: new Date() });
});

// 7. Fallback for page not found (404)
app.use((req, res, next) => {
  res.status(404).json({ success: false, message: 'Resource not found' });
});

// 8. Global Error Handler middleware
app.use(errorMiddleware);

module.exports = app;
