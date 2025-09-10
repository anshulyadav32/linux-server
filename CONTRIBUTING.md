# Contributing to Linux Server Automation Suite

Thank you for your interest in contributing to the Linux Server Automation Suite! We welcome contributions from the community.

## 🤝 How to Contribute

### Reporting Issues
- Use the [GitHub Issues](https://github.com/anshulyadav32/linux-server/issues) tracker
- Provide detailed information about your environment and the issue
- Include relevant log outputs and error messages

### Suggesting Enhancements
- Open an issue with the `enhancement` label
- Describe the feature and its benefits
- Provide implementation suggestions if possible

### Code Contributions

#### Prerequisites
- Fork the repository
- Create a feature branch from `main`
- Ensure your code follows the project's coding standards

#### Development Guidelines
1. **Shell Script Standards**:
   - Use `#!/bin/bash` shebang
   - Enable strict mode: `set -euo pipefail`
   - Use meaningful variable names
   - Add comments for complex logic

2. **Function Standards**:
   - Use consistent naming conventions
   - Add error handling with appropriate exit codes
   - Include logging using the common logging functions

3. **Module Standards**:
   - Each module must have install, check, and update scripts
   - Use the common function library (`modules/common.sh`)
   - Follow the established directory structure

#### Testing
- Test your changes on supported Linux distributions
- Ensure scripts work with both interactive and non-interactive execution
- Verify compatibility with existing modules

#### Pull Request Process
1. Update documentation if needed
2. Add or update tests for new functionality
3. Ensure all tests pass
4. Update the README.md with details of changes if applicable
5. Submit a pull request with a clear title and description

## 📝 Coding Standards

### Shell Script Style Guide
- Indent with 2 or 4 spaces (be consistent)
- Use double quotes for variable expansion
- Use `$()` instead of backticks for command substitution
- Check return values of important commands

### Documentation
- Comment complex functions and logic
- Update README.md for user-facing changes
- Include examples in function documentation

### Error Handling
- Use appropriate exit codes (0 for success, non-zero for errors)
- Provide meaningful error messages
- Log errors appropriately using the logging framework

## 🔍 Code Review Process

1. All submissions require review
2. Maintainers will review for:
   - Code quality and standards compliance
   - Security considerations
   - Compatibility with existing functionality
   - Documentation completeness

## 📄 License

By contributing to this project, you agree that your contributions will be licensed under the MIT License.

## 🆘 Getting Help

- Join our discussions in the GitHub repository
- Check existing issues and documentation
- Reach out to maintainers for guidance

Thank you for contributing to making Linux server management easier for everyone! 🚀
