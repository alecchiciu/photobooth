# n8n Workflow Builder Project

## Project Purpose
This project is dedicated to creating, managing, and updating n8n workflows. The goal is to build high-quality, production-ready automation workflows using AI-assisted development.

---

## Available Tools

### 1. n8n MCP Server
**Repository:** https://github.com/czlonkowski/n8n-mcp

A Model Context Protocol server that provides structured access to 1,084 n8n nodes (537 core + 547 community) with comprehensive documentation and operational capabilities.

#### Documentation Tools (Always Available)

| Tool | Purpose |
|------|---------|
| `tools_documentation` | Get documentation for any MCP tool - starting reference point |
| `search_nodes` | Full-text search across nodes with source filtering (all/core/community/verified) |
| `get_node` | Retrieve node info, docs, properties, or versions with flexible detail levels |
| `validate_node` | Validate node configurations with profiles: minimal, runtime, ai-friendly, strict |
| `validate_workflow` | Complete workflow validation including AI Agent validation |
| `search_templates` | Access 2,709 templates by keyword, nodes, task, metadata, or complexity |
| `get_template` | Retrieve complete workflow JSON from templates |

#### Workflow Management Tools (Requires N8N_API_KEY)

| Tool | Purpose |
|------|---------|
| `n8n_create_workflow` | Deploy new workflows with full structure |
| `n8n_get_workflow` | Retrieve workflows with configurable detail levels |
| `n8n_update_full_workflow` | Complete workflow replacement |
| `n8n_update_partial_workflow` | Batch updates using diff operations (token-efficient) |
| `n8n_delete_workflow` | Permanently remove workflows |
| `n8n_list_workflows` | Browse workflows with status filtering |
| `n8n_workflow_versions` | Manage history and rollback to previous versions |

#### Execution Tools

| Tool | Purpose |
|------|---------|
| `n8n_test_workflow` | Auto-detects trigger type; supports webhooks, forms, chat |
| `n8n_executions` | List, retrieve, or delete execution records |
| `n8n_validate_workflow` | Validate deployed workflow by ID |
| `n8n_autofix_workflow` | Automatically fix common workflow errors |
| `n8n_deploy_template` | Deploy n8n.io templates directly with auto-fix |
| `n8n_health_check` | Verify n8n API connectivity and available features |

---

### 2. n8n Skills
**Repository:** https://github.com/czlonkowski/n8n-skills

Seven complementary Claude Code skills that activate automatically based on context.

#### Skill 1: n8n Expression Syntax
**Activates when:** Writing expressions with `{{}}`, accessing variables, troubleshooting expression errors

**Key knowledge:**
- Core variables: `$json`, `$node`, `$now`, `$env`
- **Critical:** Webhook data is accessed via `$json.body`, not directly
- Common expression mistakes and fixes

#### Skill 2: n8n MCP Tools Expert (Highest Priority)
**Activates when:** Searching nodes, validating configs, accessing templates, managing workflows

**Key knowledge:**
- Tool selection framework for specific tasks
- nodeType format: `n8n-nodes-base.nodeName`
- Validation profiles: minimal (fast), runtime, ai-friendly, strict
- Smart parameters (e.g., `branch="true"` for IF nodes)

#### Skill 3: n8n Workflow Patterns
**Activates when:** Creating workflows, connecting nodes, designing automation

**Five proven patterns:**
1. Webhook processing
2. HTTP API calls
3. Database operations
4. AI integration
5. Scheduled tasks

#### Skill 4: n8n Validation Expert
**Activates when:** Validation failures, debugging errors, handling false positives

**Key knowledge:**
- Systematic validation loop workflow
- Auto-sanitization behavior
- False positive identification
- Profile selection for different stages

#### Skill 5: n8n Node Configuration
**Activates when:** Configuring nodes, property dependencies, AI workflow setup

**Key knowledge:**
- Property dependencies (e.g., `sendBody` requires `contentType`)
- Operation-specific requirements
- Eight AI connection types for Agent workflows

#### Skill 6: n8n Code JavaScript
**Activates when:** Writing JS in Code nodes, troubleshooting Code node errors

**Key knowledge:**
- Data access: `$input.all()`, `$input.first()`, `$input.item`
- **Critical:** Webhook data under `$json.body`
- Return format: `[{json: {...}}]`
- Built-ins: `$helpers.httpRequest()`, `DateTime`, `$jmespath()`
- Top 5 error patterns cover 62%+ of failures

#### Skill 7: n8n Code Python
**Activates when:** Writing Python in Code nodes

**Key knowledge:**
- Use JavaScript for 95% of use cases
- Data access: `_input`, `_json`, `_node`
- **Limitation:** No external libraries (no requests, pandas, numpy)
- Only standard library available (json, datetime, re, etc.)

---

## Critical Gotchas

1. **Webhook data access:** Always use `$json.body` for webhook payloads
2. **nodeType format:** Use `n8n-nodes-base.nodeName` (not `nodes-base.*`)
3. **Code node returns:** Must return `[{json: {...}}]` format
4. **Python limitations:** No pip packages, standard library only
5. **Production safety:** NEVER edit production workflows directly - copy first!

---

## IMPORTANT: Direct n8n Deployment

**NEVER create JSON files for manual import.** Always use MCP tools to deploy workflows directly to the n8n instance.

### Required Approach
1. Use `n8n_create_workflow` to create workflows directly in n8n
2. Use `n8n_update_partial_workflow` for iterative changes
3. Use `n8n_validate_workflow` to verify before activation
4. Use `n8n_test_workflow` to test the deployed workflow

### Why Direct Deployment?
- Immediate feedback on errors
- Credentials are linked automatically
- No manual import steps
- Workflow IDs are returned for further operations
- Enables iterative development workflow

### Workflow Creation Pattern
```
1. n8n_create_workflow({name, nodes, connections}) → returns workflow ID
2. n8n_validate_workflow({id}) → check for errors
3. n8n_update_partial_workflow({id, operations}) → fix issues iteratively
4. n8n_test_workflow({workflowId}) → test execution
5. n8n_update_partial_workflow({id, operations: [{type: "activateWorkflow"}]}) → go live
```

---

## Workflow Development Process

### 1. Discovery
```
1. Use search_nodes to find required nodes
2. Use search_templates to find similar workflows
3. Use get_node with mode='docs' for detailed documentation
```

### 2. Design
```
1. Choose appropriate workflow pattern
2. Map data flow between nodes
3. Plan error handling strategy
```

### 3. Build
```
1. Use n8n_create_workflow or work from template
2. Configure nodes with correct properties
3. Use validate_node with profile='ai-friendly' during development
```

### 4. Validate
```
1. Use validate_workflow for complete validation
2. Use n8n_autofix_workflow for common issues
3. Address any validation errors
```

### 5. Test
```
1. Use n8n_test_workflow with sample data
2. Check n8n_executions for results
3. Debug any failures
```

### 6. Deploy
```
1. Final validation with profile='strict'
2. Activate workflow
3. Monitor initial executions
```

---

## Quality Standards

### Naming Conventions
- **Workflows:** `[Category] - Descriptive Name` (e.g., `[CRM] - Sync Contacts to Mailchimp`)
- **Nodes:** Clear, action-based names (e.g., `Fetch Customer Data`, `Send Notification`)

### Error Handling
- Add Error Trigger workflows for critical automations
- Use try/catch patterns where appropriate
- Log errors for debugging
- Send notifications for critical failures

### Best Practices
1. **Modularity:** Break complex workflows into sub-workflows
2. **Documentation:** Add sticky notes explaining complex logic
3. **Credentials:** Never hardcode - use n8n credentials system
4. **Rate Limiting:** Respect API limits with delays
5. **Data Validation:** Validate at workflow entry points
6. **Version Control:** Use workflow versions for rollback capability

---

## Validation Profiles

| Profile | Speed | Use Case |
|---------|-------|----------|
| `minimal` | <100ms | Quick required field checks during development |
| `runtime` | Medium | Pre-deployment validation |
| `ai-friendly` | Medium | Best for AI-assisted development |
| `strict` | Slower | Final production validation |

---

## Common Commands Quick Reference

```
# Search for a node
search_nodes(query="slack", source="core")

# Get node documentation
get_node(nodeType="n8n-nodes-base.slack", mode="docs")

# Validate a configuration
validate_node(nodeType="n8n-nodes-base.httpRequest", config={...}, profile="ai-friendly")

# Find workflow templates
search_templates(searchMode="by_task", task="send slack notification")

# Create and test workflow
n8n_create_workflow(nodes=[...], connections={...})
n8n_test_workflow(workflowId="123")

# Check execution results
n8n_executions(action="list", workflowId="123")
```
