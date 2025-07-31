# Contributing to Rewind Data Processor

Thank you for your interest in contributing to the Rewind Data Processor! This document provides guidelines for contributing to this project.

## Getting Started

1. Fork the repository
2. Clone your fork locally
3. Create a feature branch: `git checkout -b feature/your-feature-name`
4. Make your changes
5. Test your changes thoroughly
6. Commit your changes: `git commit -m "Add feature: description"`
7. Push to your fork: `git push origin feature/your-feature-name`
8. Create a Pull Request

## Development Guidelines

### Code Style

- Follow the existing bash script conventions
- Use meaningful variable names
- Add comments for complex logic
- Ensure all scripts are executable (`chmod +x script.sh`)

### Testing

- Test your changes on macOS (the primary target platform)
- Verify that scripts work with both Intel and Apple Silicon Macs
- Test with different Rewind data formats and sizes
- Update tests if you modify existing functionality

### Documentation

- Update README.md if you add new features
- Add comments to explain complex functionality
- Update configuration examples if needed

## Areas for Contribution

### High Priority
- Performance optimizations for large datasets
- Additional OCR language support
- Enhanced speaker diarization
- Better error handling and recovery

### Medium Priority
- Support for additional video formats
- Integration with other AI services
- Web interface for configuration
- Docker containerization

### Low Priority
- Windows/Linux compatibility
- Additional export formats
- Plugin architecture

## Reporting Issues

When reporting issues, please include:

1. macOS version
2. Rewind.ai version
3. Steps to reproduce
4. Expected vs actual behavior
5. Relevant log files (if any)

## Questions?

Feel free to open an issue for questions or discussions about the project direction.