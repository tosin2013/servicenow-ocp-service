# Documentation Navigation Guide

This guide helps you navigate our documentation efficiently using the Diataxis framework.

## Documentation Framework

Our documentation follows the **Diataxis framework**, which organizes content into four quadrants based on user needs:

```
        Practical                    Theoretical
    +--------------+            +--------------+
    |              |            |              |
    |   Tutorial   |            | Explanation  |
    |              |            |              |
Study +--------------+ -------- +--------------+ Study
    |              |            |              |
    |   How-to     |            |  Reference   |
    |              |            |              |
    +--------------+            +--------------+
        Work                         Work
```

## 🎓 When to Use Tutorials

**Use tutorials when you're new to the project and want to learn by doing.**

**Purpose**: Learning-oriented guides that teach through hands-on practice.

**Best for**:
- First-time users who want to understand the system
- Learning the basic concepts and workflows
- Building confidence through successful completion
- Getting familiar with the technology stack

**Available Tutorials**:
- [Getting Started](tutorials/getting-started.md) - Complete setup walkthrough (105 minutes)
- [Your First Project](tutorials/your-first-project.md) - Hands-on project creation
- [Ansible Automation Guide](tutorials/ansible-automation-guide.md) - Learn Ansible automation
- [Execution Environment Guide](tutorials/execution-environment-guide.md) - Container environment setup

**Navigation Tip**: Start here if you're new to ServiceNow-OpenShift integration.

---

## 🛠️ When to Use How-To Guides

**Use how-to guides when you have a specific task to accomplish.**

**Purpose**: Task-oriented guides that solve specific problems.

**Best for**:
- Implementing specific features
- Solving particular problems
- Achieving specific goals
- Users with some experience who need to accomplish something

**Available How-To Guides**:

### Configuration and Setup
- [AAP Token Setup](how-to/aap-token-setup.md) - Configure API tokens
- [Working with Ansible](how-to/working-with-ansible.md) - Ansible best practices
- [Working with Execution Environment](how-to/working-with-execution-environment.md) - Container configuration

### Integration Implementation
- [Business Rule Logic](how-to/business-rule-logic.md) - Implement ServiceNow automation
- [End-to-End Testing](how-to/end-to-end-testing.md) - Testing procedures
- [Debugging Integration Issues](how-to/debugging-integration-issues.md) - Troubleshooting

### Production Operations
- [Deploy to Production](how-to/deploy-to-production.md) - Production deployment
- [Scale for Production](how-to/scale-for-production.md) - Performance optimization
- [Backup and Recovery](how-to/backup-and-recovery.md) - Data protection

**Navigation Tip**: Use when you know what you want to achieve but need step-by-step guidance.

---

## 📖 When to Use Reference Documentation

**Use reference when you need to look up specific information.**

**Purpose**: Information-oriented documentation that describes the system.

**Best for**:
- Looking up API endpoints
- Finding configuration options
- Understanding command syntax
- Quick fact-checking
- Troubleshooting error codes

**Available Reference Documentation**:
- [Shell Scripts Reference](reference/shell-scripts-reference.md) - Complete script documentation
- [API Reference](reference/api-reference.md) - REST API endpoints
- [Ansible Reference](reference/ansible-reference.md) - Playbooks and variables
- [Configuration Variables](reference/configuration-variables.md) - All configuration options
- [Troubleshooting Reference](reference/troubleshooting-reference.md) - Error codes and solutions

**Navigation Tip**: Use when you need to find specific facts or look up syntax.

---

## 💡 When to Use Explanation

**Use explanation when you need to understand concepts and context.**

**Purpose**: Understanding-oriented documentation that provides context and background.

**Best for**:
- Understanding the "why" behind design decisions
- Learning about architectural patterns
- Getting context about the problem space
- Understanding alternatives and trade-offs

**Available Explanations**:
- [Architecture Overview](explanation/architecture-overview.md) - System design principles
- [Deployment Architecture](explanation/deployment-architecture.md) - Infrastructure patterns
- [Security Architecture](explanation/security-architecture.md) - Security design
- [User Workflows Analysis](explanation/user-workflows-analysis.md) - Workflow design rationale

**Navigation Tip**: Use when you need to understand concepts, not just accomplish tasks.

---

## 🗺️ Recommended Learning Paths

### For Complete Beginners
1. **Start with Explanation**: [Architecture Overview](explanation/architecture-overview.md) - Understand what you're building
2. **Follow Tutorial**: [Getting Started](tutorials/getting-started.md) - Learn through hands-on practice
3. **Try How-To**: [Your First Project](tutorials/your-first-project.md) - Accomplish something real
4. **Use Reference**: As needed for specific lookups

### For Experienced Users
1. **Scan How-To Guides**: Find the specific task you need to accomplish
2. **Reference Documentation**: Look up specific syntax and parameters
3. **Explanation**: When you need to understand the reasoning behind implementations

### For System Administrators
1. **How-To Guides**: [Deploy to Production](how-to/deploy-to-production.md), [Scale for Production](how-to/scale-for-production.md)
2. **Reference**: [Configuration Variables](reference/configuration-variables.md), [Troubleshooting Reference](reference/troubleshooting-reference.md)
3. **Explanation**: [Security Architecture](explanation/security-architecture.md)

### For Developers Contributing to the Project
1. **How-To**: [Contribute](how-to/contribute.md)
2. **Reference**: [Shell Scripts Reference](reference/shell-scripts-reference.md)
3. **Explanation**: [Architecture Overview](explanation/architecture-overview.md)

---

## 📱 Quick Navigation Tips

### By User Type
- **🆕 New Users**: Start with [Tutorials](tutorials/) → [How-To Guides](how-to/)
- **🔧 Implementers**: Focus on [How-To Guides](how-to/) → [Reference](reference/)
- **🏗️ Architects**: Emphasize [Explanation](explanation/) → [Reference](reference/)
- **🚨 Troubleshooters**: Go directly to [Reference](reference/troubleshooting-reference.md)

### By Time Available
- **⚡ 5 minutes**: [Reference](reference/) - Quick lookups
- **🕐 30 minutes**: [How-To Guides](how-to/) - Specific tasks
- **⏰ 2+ hours**: [Tutorials](tutorials/) - Learning sessions
- **🤔 Variable**: [Explanation](explanation/) - Understanding concepts

### By Goal
- **Learn the system**: [Tutorials](tutorials/)
- **Solve a problem**: [How-To Guides](how-to/)
- **Look something up**: [Reference](reference/)
- **Understand concepts**: [Explanation](explanation/)

---

## 🔍 Search and Discovery

### When You Don't Know Where to Start
1. Check the [Architecture Overview](explanation/architecture-overview.md) for context
2. Browse the [Getting Started Tutorial](tutorials/getting-started.md) for a guided introduction
3. Look through [How-To Guides](how-to/) for task-specific guidance

### When You're Looking for Something Specific
1. Try the [Reference](reference/) section first
2. Use the search functionality (if available)
3. Check related how-to guides for context

### When You're Stuck on a Problem
1. Start with [Debugging Integration Issues](how-to/debugging-integration-issues.md)
2. Check [Troubleshooting Reference](reference/troubleshooting-reference.md)
3. Review relevant explanation documents for context

---

## 📞 Getting Help

If you can't find what you need in the documentation:

1. **Check Recent Updates**: Documentation is continuously improved
2. **Search Issues**: Look for similar problems in the issue tracker
3. **Ask for Help**: Create an issue with:
   - What you were trying to do
   - What section of documentation you checked
   - What you expected vs. what happened

---

## 📈 Documentation Feedback

Help us improve the documentation:
- **Found something unclear?** Open an issue
- **Missing information?** Request additions
- **Found an error?** Submit a correction
- **Have suggestions?** Share your feedback

The documentation follows the Diataxis framework to ensure it serves different user needs effectively. Understanding this structure will help you find information more efficiently and use the ServiceNow-OpenShift integration more effectively.