# Project configuration

From the project root run `"<skill-root>/scripts/firefly.sh" config` before applying project-specific instructions or selecting a model. The command returns the resolved model tiers and validated playbook paths. It reads files without changing the project.

- `.firefly/models.json` may map a subset of the default roles in [model-policy.json](model-policy.json) to `cheap`, `standard` or `top`. A tier is a preference for the available host tools. Use the host default when it offers no equivalent. A tier never relaxes role separation or evidence requirements.
- Each `.firefly/playbooks/*.md` can add a project-specific check or clarify a project convention at an existing heading. Its first lines are:

  ```markdown
  ---
  extends: firefly-review
  anchor: 8. Resolve several returns
  ---
  Describe how to reproduce the project's checks.
  ```

  Open only the listed playbooks for the current guide and anchor. These project instructions can specialize an existing step within user authorization. They cannot override a mandate, widen write scope, suppress a required check, rewrite the verdict rules, or add an automatic trigger. Report invalid configuration at the affected entry.
