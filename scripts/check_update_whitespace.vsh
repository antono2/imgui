// Check maintained and generated files while preserving copied Dear ImGui whitespace.
import os

result := os.exec(['git', 'diff', '--check', '--', '.', ':(exclude)include/imgui/**'])
print(result.output)
exit(result.exit_code)
