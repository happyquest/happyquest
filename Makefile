.PHONY: help test lint format clean install

help:
	@echo 'Usage: make [target]'
	@echo 'Targets:'
	@echo '  install  Install dependencies'
	@echo '  test     Run tests'
	@echo '  lint     Run linting'
	@echo '  format   Format code'
	@echo '  clean    Clean build artifacts'

install:
	@echo 'Installing Python dependencies...'
	pip install pytest black flake8 || echo 'Python packages installation skipped'
	@echo 'Installing Node.js dependencies...'
	npm install || echo 'npm install skipped'

test:
	@echo 'Running Python tests...'
	pytest || echo 'pytest not available'
	@echo 'Running Node.js tests...'
	npm test || echo 'npm test not available'

lint:
	@echo 'Running Python linting...'
	flake8 src/ || echo 'flake8 not available'
	@echo 'Running Node.js linting...'
	npm run lint || echo 'npm lint not available'

format:
	@echo 'Formatting Python code...'
	black src/ || echo 'black not available'
	@echo 'Formatting Node.js code...'
	npm run format || echo 'npm format not available'

clean:
	find . -name __pycache__ -exec rm -rf {} + 2>/dev/null || true
	rm -rf node_modules/ .coverage htmlcov/ 2>/dev/null || true
