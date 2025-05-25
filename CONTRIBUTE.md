# Contributing to Blinko

[中文版本](./CONTRIBUTE.zh-CN.md) | English

Welcome to the Blinko project! We're excited to have you contribute to this innovative note-taking and knowledge management platform. This guide will help you get started with development and understand our contribution workflow.

## Table of Contents

- [Overview](#overview)
- [Getting Started](#getting-started)
- [Development Environment Setup](#development-environment-setup)
- [Project Structure](#project-structure)
- [Development Workflow](#development-workflow)
- [Coding Standards](#coding-standards)
- [Testing](#testing)
- [Plugin Development](#plugin-development)
- [Contributing Process](#contributing-process)
- [Release Process](#release-process)
- [Community & Support](#community--support)

## Overview

Blinko is a modern, self-hosted note-taking and knowledge management platform built with cutting-edge technologies:

- **Frontend**: React + Vite + Tauri (Web + Desktop)
- **Backend**: Express + tRPC + Prisma
- **Database**: PostgreSQL
- **Package Manager**: Bun
- **Deployment**: Docker + Docker Compose

The project follows a monorepo structure with separate frontend (`app/`) and backend (`server/`) directories.

## Getting Started

### Prerequisites

Before you begin, ensure you have the following installed:

- **Bun** >= 1.0.0 ([Installation Guide](https://bun.sh/docs/installation))
- **Node.js** >= 20.0.0
- **PostgreSQL** >= 14
- **Git**
- **Docker** and **Docker Compose** (optional, for containerized development)

### Quick Setup

1. **Clone the repository**
   ```bash
   git clone https://github.com/blinko-space/blinko.git
   cd blinko
   ```

2. **Install dependencies**
   ```bash
   bun install
   ```

3. **Set up the database**
   ```bash
   # Start PostgreSQL (if not running)
   # Create database
   createdb blinko
   
   # Run migrations
   cd server
   bun run db:migrate
   ```

4. **Configure environment**
   ```bash
   # Copy environment files
   cp server/.env.example server/.env
   cp app/.env.example app/.env
   
   # Edit the .env files with your configuration
   ```

5. **Start development servers**
   ```bash
   # In the root directory
   bun run dev
   ```

This will start both the frontend (http://localhost:3000) and backend (http://localhost:3001) development servers.

## Development Environment Setup

### Environment Variables

Create the following environment files:

**server/.env**
```env
DATABASE_URL="postgresql://username:password@localhost:5432/blinko"
JWT_SECRET="your-jwt-secret"
PORT=3001
NODE_ENV=development
```

**app/.env**
```env
VITE_SERVER_URL=http://localhost:3001
VITE_APP_NAME=Blinko
```

### Database Setup

1. **Create PostgreSQL database**
   ```bash
   createdb blinko
   ```

2. **Run Prisma migrations**
   ```bash
   cd server
   bun run db:migrate
   ```

3. **Seed database (optional)**
   ```bash
   bun run db:seed
   ```

### Docker Development

For a containerized development environment:

```bash
# Start all services
docker-compose up -d

# View logs
docker-compose logs -f

# Stop services
docker-compose down
```

## Project Structure

```
blinko/
├── app/                    # Frontend application
│   ├── src/
│   │   ├── components/     # React components
│   │   ├── pages/         # Page components
│   │   ├── hooks/         # Custom React hooks
│   │   ├── utils/         # Utility functions
│   │   ├── stores/        # State management
│   │   └── styles/        # CSS and styling
│   ├── public/            # Static assets
│   └── package.json
├── server/                # Backend application
│   ├── src/
│   │   ├── routes/        # API routes
│   │   ├── middleware/    # Express middleware
│   │   ├── services/      # Business logic
│   │   ├── models/        # Database models
│   │   └── utils/         # Server utilities
│   ├── prisma/           # Database schema and migrations
│   └── package.json
├── plugins/              # Plugin system
├── docs/                 # Documentation
├── docker-compose.yml    # Docker configuration
└── package.json         # Root package.json
```

## Development Workflow

### Branch Strategy

- `main` - Production-ready code
- `develop` - Development integration branch
- `feature/*` - Feature development branches
- `bugfix/*` - Bug fix branches
- `hotfix/*` - Emergency fixes for production

### Development Process

1. **Create a feature branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. **Make your changes**
   - Follow our coding standards
   - Add tests for new functionality
   - Update documentation as needed

3. **Test your changes**
   ```bash
   # Run tests
   bun test
   
   # Run linting
   bun run lint
   
   # Type checking
   bun run type-check
   ```

4. **Commit your changes**
   ```bash
   git add .
   git commit -m "feat: add new feature description"
   ```

5. **Push and create a Pull Request**
   ```bash
   git push origin feature/your-feature-name
   ```

### Common Commands

```bash
# Development
bun run dev              # Start both frontend and backend
bun run dev:app          # Start only frontend
bun run dev:server       # Start only backend

# Building
bun run build            # Build both applications
bun run build:app        # Build frontend
bun run build:server     # Build backend

# Testing
bun test                 # Run all tests
bun run test:app         # Run frontend tests
bun run test:server      # Run backend tests

# Database
bun run db:migrate       # Run database migrations
bun run db:reset         # Reset database
bun run db:seed          # Seed database

# Linting and formatting
bun run lint             # Run ESLint
bun run lint:fix         # Fix linting issues
bun run format           # Format code with Prettier

# Desktop app (Tauri)
bun run tauri:dev        # Start Tauri development
bun run tauri:build      # Build desktop application
```

## Coding Standards

### TypeScript

- Use TypeScript for all new code
- Define proper types and interfaces
- Avoid `any` type; use proper typing
- Use meaningful variable and function names

```typescript
// Good
interface User {
  id: string;
  email: string;
  createdAt: Date;
}

const createUser = async (userData: Omit<User, 'id' | 'createdAt'>): Promise<User> => {
  // Implementation
};

// Avoid
const createUser = (data: any): any => {
  // Implementation
};
```

### React Components

- Use functional components with hooks
- Follow the component naming convention (PascalCase)
- Use TypeScript interfaces for props
- Keep components small and focused

```tsx
// Good
interface NoteCardProps {
  note: Note;
  onEdit: (id: string) => void;
  onDelete: (id: string) => void;
}

export const NoteCard: React.FC<NoteCardProps> = ({ note, onEdit, onDelete }) => {
  return (
    <div className="note-card">
      <h3>{note.title}</h3>
      <p>{note.content}</p>
      <div className="note-actions">
        <button onClick={() => onEdit(note.id)}>Edit</button>
        <button onClick={() => onDelete(note.id)}>Delete</button>
      </div>
    </div>
  );
};
```

### CSS and Styling

- Use Tailwind CSS for styling
- Follow BEM methodology for custom CSS
- Use CSS modules when needed
- Keep styles modular and reusable

```css
/* Good - BEM methodology */
.note-card {
  @apply bg-white rounded-lg shadow-md p-4;
}

.note-card__title {
  @apply text-lg font-semibold mb-2;
}

.note-card__content {
  @apply text-gray-700 mb-4;
}

.note-card__actions {
  @apply flex gap-2;
}
```

### API Development

- Use tRPC for type-safe APIs
- Follow RESTful principles
- Implement proper error handling
- Add request validation

```typescript
// Good
export const noteRouter = t.router({
  getAll: t.procedure
    .input(z.object({
      page: z.number().min(1).default(1),
      limit: z.number().min(1).max(100).default(10),
    }))
    .query(async ({ input }) => {
      const { page, limit } = input;
      const offset = (page - 1) * limit;
      
      const notes = await prisma.note.findMany({
        skip: offset,
        take: limit,
        orderBy: { createdAt: 'desc' },
      });
      
      return {
        notes,
        pagination: {
          page,
          limit,
          total: await prisma.note.count(),
        },
      };
    }),
});
```

## Testing

### Frontend Testing

We use Vitest and React Testing Library for frontend testing.

```typescript
// Example component test
import { render, screen, fireEvent } from '@testing-library/react';
import { describe, it, expect, vi } from 'vitest';
import { NoteCard } from './NoteCard';

describe('NoteCard', () => {
  const mockNote = {
    id: '1',
    title: 'Test Note',
    content: 'Test content',
    createdAt: new Date(),
  };

  it('renders note information correctly', () => {
    render(
      <NoteCard 
        note={mockNote} 
        onEdit={vi.fn()} 
        onDelete={vi.fn()} 
      />
    );
    
    expect(screen.getByText('Test Note')).toBeInTheDocument();
    expect(screen.getByText('Test content')).toBeInTheDocument();
  });

  it('calls onEdit when edit button is clicked', () => {
    const onEdit = vi.fn();
    render(
      <NoteCard 
        note={mockNote} 
        onEdit={onEdit} 
        onDelete={vi.fn()} 
      />
    );
    
    fireEvent.click(screen.getByText('Edit'));
    expect(onEdit).toHaveBeenCalledWith('1');
  });
});
```

### Backend Testing

We use Vitest for backend testing with database integration.

```typescript
// Example API test
import { describe, it, expect, beforeEach, afterEach } from 'vitest';
import { createTestContext } from '../utils/test-context';
import { noteRouter } from './note.router';

describe('Note Router', () => {
  let ctx: TestContext;

  beforeEach(async () => {
    ctx = await createTestContext();
  });

  afterEach(async () => {
    await ctx.cleanup();
  });

  it('should create a new note', async () => {
    const input = {
      title: 'Test Note',
      content: 'Test content',
    };

    const result = await noteRouter.create({
      input,
      ctx: ctx.context,
    });

    expect(result.title).toBe('Test Note');
    expect(result.content).toBe('Test content');
    expect(result.id).toBeDefined();
  });
});
```

### Running Tests

```bash
# Run all tests
bun test

# Run tests in watch mode
bun test --watch

# Run tests with coverage
bun test --coverage

# Run specific test file
bun test src/components/NoteCard.test.tsx
```

## Plugin Development

Blinko supports a plugin system for extending functionality. Plugins are located in the `plugins/` directory.

### Plugin Structure

```
plugins/
├── example-plugin/
│   ├── src/
│   │   ├── index.ts       # Plugin entry point
│   │   ├── components/    # React components
│   │   └── api/          # API endpoints
│   ├── package.json      # Plugin metadata
│   └── README.md         # Plugin documentation
```

### Creating a Plugin

1. **Create plugin directory**
   ```bash
   mkdir plugins/my-plugin
   cd plugins/my-plugin
   ```

2. **Initialize plugin**
   ```bash
   bun init
   ```

3. **Define plugin structure**
   ```typescript
   // src/index.ts
   import { Plugin } from '@blinko/plugin-api';

   export default class MyPlugin extends Plugin {
     name = 'my-plugin';
     version = '1.0.0';

     async activate() {
       // Plugin activation logic
       this.registerComponent('MyComponent', () => import('./components/MyComponent'));
       this.registerRoute('/api/my-plugin', () => import('./api/routes'));
     }

     async deactivate() {
       // Plugin cleanup logic
     }
   }
   ```

### Plugin API

```typescript
// Available plugin APIs
interface PluginAPI {
  // Component registration
  registerComponent(name: string, component: ComponentLoader): void;
  
  // Route registration
  registerRoute(path: string, handler: RouteHandler): void;
  
  // Event system
  on(event: string, handler: EventHandler): void;
  emit(event: string, data: any): void;
  
  // Storage
  getStorage(): PluginStorage;
  
  // Configuration
  getConfig(): PluginConfig;
}
```

## Contributing Process

### Before Contributing

1. Check existing issues and pull requests
2. Read the project documentation
3. Set up your development environment
4. Familiarize yourself with our coding standards

### Making Contributions

1. **Fork the repository**
2. **Create a feature branch** from `develop`
3. **Make your changes** following our guidelines
4. **Add/update tests** for your changes
5. **Update documentation** if needed
6. **Run the test suite** to ensure everything works
7. **Submit a pull request** with a clear description

### Pull Request Guidelines

- Use a clear and descriptive title
- Include a detailed description of changes
- Reference related issues using `#issue-number`
- Ensure all tests pass
- Update documentation when necessary
- Follow the commit message convention

### Commit Message Convention

We follow the [Conventional Commits](https://www.conventionalcommits.org/) specification:

```
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

Types:
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes (formatting, etc.)
- `refactor`: Code refactoring
- `test`: Adding or updating tests
- `chore`: Maintenance tasks

Examples:
```
feat(notes): add search functionality
fix(auth): resolve login token expiration issue
docs: update API documentation
test(components): add tests for NoteCard component
```

### Code Review Process

1. All submissions require review from maintainers
2. We may ask for changes or improvements
3. Once approved, your PR will be merged
4. Contributions will be credited in release notes

## Release Process

### Versioning

We follow [Semantic Versioning](https://semver.org/):
- `MAJOR.MINOR.PATCH`
- Major: Breaking changes
- Minor: New features (backward compatible)
- Patch: Bug fixes (backward compatible)

### Release Workflow

1. **Feature Freeze**: Stop adding new features
2. **Testing**: Comprehensive testing of the release candidate
3. **Documentation**: Update changelog and documentation
4. **Release**: Create release tag and publish
5. **Deployment**: Deploy to production environments

### Deployment

#### Docker Deployment

```bash
# Build and deploy with Docker Compose
docker-compose -f docker-compose.prod.yml up -d
```

#### Manual Deployment

```bash
# Build applications
bun run build

# Start production server
bun run start:prod
```

## Community & Support

### Getting Help

- **Documentation**: Check the `docs/` directory
- **Issues**: Search existing GitHub issues
- **Discussions**: Use GitHub Discussions for questions
- **Discord**: Join our Discord community (if available)

### Reporting Issues

When reporting bugs, please include:
- Steps to reproduce the issue
- Expected vs actual behavior
- Environment information (OS, browser, versions)
- Error messages and logs
- Screenshots if applicable

### Feature Requests

- Check if the feature already exists or is planned
- Clearly describe the use case and benefits
- Provide examples or mockups if possible
- Be open to discussion and feedback

### Code of Conduct

We are committed to providing a welcoming and inclusive environment. Please:
- Be respectful and considerate
- Use inclusive language
- Accept constructive criticism gracefully
- Focus on the best outcome for the community
- Show empathy towards other community members

---

Thank you for contributing to Blinko! Your efforts help make this project better for everyone. If you have any questions, don't hesitate to reach out to the maintainers or community.

## Table of Contents

- [Project Overview](#project-overview)
- [Development Environment Setup](#development-environment-setup)
- [Project Structure](#project-structure)
- [Development Workflow](#development-workflow)
- [Coding Standards](#coding-standards)
- [Testing Guidelines](#testing-guidelines)
- [Plugin Development](#plugin-development)
- [Contribution Process](#contribution-process)
- [Release Process](#release-process)
- [Getting Help](#getting-help)

## Project Overview

Blinko is a modern, cross-platform note-taking application built with cutting-edge technologies:

- **Frontend**: React 18 + Vite + Tauri (for desktop and mobile)
- **Backend**: Express.js + tRPC for type-safe APIs
- **Database**: PostgreSQL with Prisma ORM
- **Package Manager**: Bun (>= 1.0.0)
- **Platforms**: Web, Desktop (Windows/macOS/Linux), Android

### Key Features
- Real-time note synchronization
- Plugin system with hot reload
- Multi-platform support
- Advanced search and tagging
- Rich text editing with markdown support
- AI integration capabilities

## Development Environment Setup

### Prerequisites

- **Node.js**: >= 20.0.0
- **Bun**: >= 1.0.0 (preferred package manager)
- **PostgreSQL**: >= 12
- **Rust**: Latest stable (for Tauri desktop builds)
- **Android Studio**: Required for Android development
- **Git**: For version control

### Quick Start

1. **Clone the repository**
   ```bash
   git clone https://github.com/blinko-space/blinko.git
   cd blinko
   ```

2. **Install dependencies**
   ```bash
   bun install
   ```

3. **Set up environment variables**
   ```bash
   cp .env.example .env
   # Edit .env with your database credentials and other settings
   ```

4. **Set up the database**
   ```bash
   # Start PostgreSQL (if using Docker)
   docker-compose up -d postgres
   
   # Run database migrations
   cd prisma
   bun run prisma migrate dev
   
   # Seed the database (optional)
   bun run seed
   ```

5. **Start development servers**
   ```bash
   # Start both frontend and backend in development mode
   cd app
   bun run dev
   ```

The application will be available at:
- Web interface: http://localhost:1111
- API server: http://localhost:3000

### Platform-Specific Development

#### Desktop Development (Tauri)
```bash
cd app
bun run tauri:dev
```

#### Android Development
```bash
cd app
bun run tauri:android:dev
```

#### Web Development
```bash
cd app
bun run dev  # This starts the backend server which serves the frontend
```

## Project Structure

```
blinko/
├── app/                    # Frontend application
│   ├── src/
│   │   ├── components/     # React components
│   │   ├── pages/         # Page components
│   │   ├── store/         # State management (MobX)
│   │   ├── lib/           # Utility functions
│   │   └── styles/        # CSS and styling
│   ├── src-tauri/         # Tauri desktop app configuration
│   ├── tauri-plugin-blinko/ # Custom Tauri plugin
│   └── public/            # Static assets
├── server/                # Backend application
│   ├── routerTrpc/       # tRPC API routes
│   ├── routerExpress/    # Express.js routes
│   ├── middleware/       # Express middleware
│   ├── lib/              # Server utilities
│   ├── jobs/             # Background jobs
│   └── aiServer/         # AI integration services
├── prisma/               # Database schema and migrations
│   ├── schema.prisma     # Database schema
│   ├── migrations/       # Database migration files
│   └── seedfiles/        # Database seed data
├── shared/               # Shared utilities between frontend and backend
├── blinko-types/         # TypeScript type definitions
└── docker-compose.yml    # Docker configuration
```

### Key Files

- **Root `package.json`**: Workspace configuration and scripts
- **`app/package.json`**: Frontend dependencies and scripts
- **`server/package.json`**: Backend dependencies and scripts
- **`prisma/schema.prisma`**: Database schema definition
- **`docker-compose.yml`**: Docker services configuration
- **`turbo.json`**: Turborepo configuration for monorepo management

## Development Workflow

### Branch Strategy

We use a feature branch workflow:

1. **main**: Production-ready code
2. **develop**: Integration branch for features
3. **feature/**: Feature development branches
4. **hotfix/**: Critical bug fixes
5. **release/**: Release preparation branches

### Development Process

1. **Create a feature branch**
   ```bash
   git checkout develop
   git pull origin develop
   git checkout -b feature/your-feature-name
   ```

2. **Make your changes**
   - Write code following our coding standards
   - Add tests for new functionality
   - Update documentation if necessary

3. **Test your changes**
   ```bash
   # Run frontend tests
   cd app && bun run test
   
   # Run backend tests
   cd server && bun run test
   
   # Run end-to-end tests
   bun run test:e2e
   ```

4. **Commit your changes**
   ```bash
   git add .
   git commit -m "feat: add new feature description"
   ```

5. **Push and create a pull request**
   ```bash
   git push origin feature/your-feature-name
   ```

### Commit Message Convention

We follow the [Conventional Commits](https://www.conventionalcommits.org/) specification:

```
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

**Types:**
- `feat`: A new feature
- `fix`: A bug fix
- `docs`: Documentation only changes
- `style`: Changes that do not affect the meaning of the code
- `refactor`: A code change that neither fixes a bug nor adds a feature
- `perf`: A code change that improves performance
- `test`: Adding missing tests or correcting existing tests
- `chore`: Changes to the build process or auxiliary tools

**Examples:**
```
feat(api): add user authentication endpoint
fix(ui): resolve mobile navigation issue
docs(readme): update installation instructions
```

## Coding Standards

### TypeScript

- Use TypeScript for all new code
- Enable strict mode in TypeScript configuration
- Prefer `interface` over `type` for object shapes
- Use proper type annotations for function parameters and return types

```typescript
// Good
interface User {
  id: string;
  name: string;
  email: string;
}

const getUser = async (id: string): Promise<User> => {
  // implementation
};

// Avoid
const getUser = async (id: any) => {
  // implementation
};
```

### React Components

- Use functional components with hooks
- Prefer named exports over default exports
- Use proper TypeScript interfaces for props
- Follow the component file naming convention: `ComponentName.tsx`

```typescript
// Good
interface ButtonProps {
  text: string;
  onClick: () => void;
  variant?: 'primary' | 'secondary';
}

export const Button = ({ text, onClick, variant = 'primary' }: ButtonProps) => {
  return (
    <button className={`btn btn-${variant}`} onClick={onClick}>
      {text}
    </button>
  );
};
```

### CSS/Styling

- Use Tailwind CSS for styling
- Follow mobile-first responsive design
- Use semantic class names for custom components
- Avoid inline styles unless absolutely necessary

### API Development

- Use tRPC for type-safe API development
- Follow RESTful principles for Express routes
- Implement proper error handling
- Add input validation using Zod schemas

```typescript
// tRPC procedure example
export const getUserProcedure = publicProcedure
  .input(z.object({ id: z.string() }))
  .query(async ({ input }) => {
    const user = await prisma.user.findUnique({
      where: { id: input.id }
    });
    if (!user) {
      throw new TRPCError({
        code: 'NOT_FOUND',
        message: 'User not found'
      });
    }
    return user;
  });
```

### Database

- Use Prisma for database operations
- Write descriptive migration names
- Always include rollback considerations
- Use proper indexes for performance

## Testing Guidelines

### Frontend Testing

- Write unit tests for utility functions
- Use React Testing Library for component tests
- Write integration tests for complex user flows
- Aim for >80% code coverage

```typescript
// Example component test
import { render, screen, fireEvent } from '@testing-library/react';
import { Button } from './Button';

test('renders button with correct text', () => {
  const handleClick = jest.fn();
  render(<Button text="Click me" onClick={handleClick} />);
  
  const button = screen.getByRole('button', { name: /click me/i });
  expect(button).toBeInTheDocument();
  
  fireEvent.click(button);
  expect(handleClick).toHaveBeenCalledTimes(1);
});
```

### Backend Testing

- Write unit tests for business logic
- Test API endpoints with proper error cases
- Mock external dependencies
- Test database operations with test database

```typescript
// Example API test
import { createTestContext } from '../test-utils';
import { appRouter } from '../router';

test('should get user by id', async () => {
  const ctx = createTestContext();
  const caller = appRouter.createCaller(ctx);
  
  const user = await caller.user.getById({ id: 'test-user-id' });
  expect(user.id).toBe('test-user-id');
});
```

### Running Tests

```bash
# Run all tests
bun run test

# Run tests in watch mode
bun run test:watch

# Run tests with coverage
bun run test:coverage

# Run e2e tests
bun run test:e2e
```

## Plugin Development

Blinko supports a powerful plugin system that allows extending functionality without modifying core code.

### Plugin Structure

```
plugins/
└── my-plugin/
    ├── package.json
    ├── index.ts         # Main plugin entry
    ├── components/      # React components
    ├── api/            # API endpoints
    └── assets/         # Static assets
```

### Creating a Plugin

1. **Initialize plugin directory**
   ```bash
   mkdir plugins/my-plugin
   cd plugins/my-plugin
   bun init
   ```

2. **Create plugin entry point**
   ```typescript
   // index.ts
   import { PluginAPI } from '@blinko/plugin-api';
   
   export default class MyPlugin {
     constructor(private api: PluginAPI) {}
     
     async onLoad() {
       // Plugin initialization logic
       this.api.registerComponent('MyComponent', MyComponent);
       this.api.registerRoute('/api/my-plugin', myApiHandler);
     }
     
     async onUnload() {
       // Cleanup logic
     }
   }
   ```

3. **Register plugin components**
   ```typescript
   import React from 'react';
   
   export const MyComponent = () => {
     return <div>My Plugin Component</div>;
   };
   ```

### Plugin Hot Reload

During development, plugins support hot reload via WebSocket:

```bash
# Start development with plugin hot reload
cd app
PLUGIN_DEV=true bun run dev
```

### Plugin API Reference

The Plugin API provides the following capabilities:

- **Component Registration**: Register React components
- **Route Registration**: Add custom API endpoints
- **Event System**: Listen to and emit custom events
- **Storage API**: Plugin-specific data storage
- **UI Hooks**: Integrate with the main application UI

## Contribution Process

### Reporting Issues

1. **Search existing issues** to avoid duplicates
2. **Use issue templates** for bug reports and feature requests
3. **Provide detailed information**:
   - Steps to reproduce
   - Expected vs actual behavior
   - Environment details (OS, browser, versions)
   - Screenshots or videos if applicable

### Submitting Pull Requests

1. **Fork the repository** and create a feature branch
2. **Make your changes** following our coding standards
3. **Write or update tests** for your changes
4. **Update documentation** if necessary
5. **Create a pull request** with:
   - Clear title and description
   - Reference to related issues
   - Screenshots for UI changes
   - Test results

### Pull Request Review Process

1. **Automated checks** must pass (CI/CD, tests, linting)
2. **Code review** by at least one maintainer
3. **Manual testing** for significant changes
4. **Documentation review** if applicable
5. **Approval and merge** by maintainers

### Review Criteria

- **Code quality**: Follows coding standards and best practices
- **Functionality**: Works as intended and doesn't break existing features
- **Performance**: Doesn't negatively impact application performance
- **Security**: Follows security best practices
- **Documentation**: Includes necessary documentation updates
- **Tests**: Has appropriate test coverage

## Release Process

### Version Management

We follow [Semantic Versioning](https://semver.org/):

- **MAJOR**: Breaking changes
- **MINOR**: New features (backward compatible)
- **PATCH**: Bug fixes (backward compatible)

### Release Workflow

1. **Create release branch** from develop
   ```bash
   git checkout develop
   git checkout -b release/v1.2.0
   ```

2. **Update version numbers** in package.json files
3. **Update CHANGELOG.md** with release notes
4. **Create release PR** to main branch
5. **After merge, tag the release**
   ```bash
   git tag v1.2.0
   git push origin v1.2.0
   ```

6. **Deploy to production** (automated via GitHub Actions)

### Build and Deployment

#### Production Builds

```bash
# Build web application
cd app && bun run build:web

# Build desktop application
cd app && bun run tauri:desktop:build

# Build Android application
cd app && bun run tauri:android:build
```

#### Docker Deployment

```bash
# Build and run with Docker Compose
docker-compose -f docker-compose.prod.yml up -d

# Or use the install script
./install.sh
```

## Getting Help

### Community Resources

- **GitHub Discussions**: For questions and community support
- **GitHub Issues**: For bug reports and feature requests
- **Documentation**: Check the README.md and docs/ folder
- **Wiki**: Additional guides and tutorials

### Development Support

- **Code Review**: Tag maintainers in PRs for review
- **Architecture Questions**: Open a discussion for design decisions
- **Bug Reports**: Use the bug report template with detailed information

### Maintainers

- **Core Team**: @maintainer1, @maintainer2
- **Plugin System**: @plugin-maintainer
- **Mobile Platform**: @mobile-maintainer

### Communication Guidelines

- **Be respectful** and inclusive in all interactions
- **Search existing discussions** before asking questions
- **Provide context** when asking for help
- **Follow up** on conversations and issues

## License

By contributing to Blinko, you agree that your contributions will be licensed under the same license as the project.

---

Thank you for contributing to Blinko! Your efforts help make this project better for everyone. 🚀
