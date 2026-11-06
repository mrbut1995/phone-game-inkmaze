== OUTPUT FORMAT (strict - a tool parses your answer) ==
1. SUMMARY: at most 10 lines - what you changed and why.
2. For every file you create or change output the COMPLETE file (never a diff, never "..." or "unchanged"). Put a line `FILE: <path relative to the project root>` and directly under it one fenced code block:

FILE: scripts/screens/ExampleScene.gd
```gdscript
<complete file content>
```

3. To delete a file output a line `DELETE: <path>`.
4. .gd files use TABS for indentation. LF line endings. Do not invent uid= values in .tscn/.tres: reference resources by path.
5. Only touch files that are necessary. Allowed folders: scenes/ scripts/ data/ tests/ assets/images-placeholder/ plan/ docs/.
6. Finish with `NOTES:` - assumptions, anything you could not do, and the tests you added.
If information is missing, ask BEFORE writing files and list the exact questions.
