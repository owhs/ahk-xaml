import * as vscode from 'vscode';
import { ELEMENTS, PROPERTIES, EVENTS, RESOURCES, ICONS } from './db';

export function activate(context: vscode.ExtensionContext) {
    console.log('AHK-XAML extension is active!');

    const config = vscode.workspace.getConfiguration('axml');
    const customProps: string[] = config.get('customProperties') || [];
    const commonFixes: { [key: string]: string } = config.get('commonFixes') || {};

    // Helper to get element indentation level
    function getIndentLength(lineText: string): number {
        const match = lineText.match(/^\\s*/);
        return match ? match[0].length : 0;
    }

    // 1. Autocomplete Provider
    const completionProvider = vscode.languages.registerCompletionItemProvider(
        'axml',
        {
            provideCompletionItems(document: vscode.TextDocument, position: vscode.Position) {
                const linePrefix = document.lineAt(position).text.substring(0, position.character);
                const completions: vscode.CompletionItem[] = [];

                // Check for DynamicResource completion
                if (linePrefix.match(/\{DynamicResource\s+[a-zA-Z0-9_]*$/)) {
                    for (const res of RESOURCES) {
                        const item = new vscode.CompletionItem(res.name, vscode.CompletionItemKind.Color);
                        item.detail = "DynamicResource";
                        item.documentation = new vscode.MarkdownString(res.description);
                        completions.push(item);
                    }
                    return completions;
                }

                // Check for Segoe Fluent Icons completion
                const isContentOrText = linePrefix.match(/(Content|Text)\\s*:\\s*".*$/);
                if (isContentOrText) {
                    for (const icon of ICONS) {
                        const item = new vscode.CompletionItem(icon.name, vscode.CompletionItemKind.Text);
                        item.detail = "Segoe Fluent Icon";
                        item.documentation = new vscode.MarkdownString(icon.description);
                        completions.push(item);
                    }
                }

                // Standard Elements
                for (const el of ELEMENTS) {
                    const item = new vscode.CompletionItem(el.name, vscode.CompletionItemKind.Class);
                    if (el.snippet) {
                        item.insertText = new vscode.SnippetString(el.snippet);
                    } else {
                        item.insertText = new vscode.SnippetString(`${el.name}:\n  $0`);
                    }
                    item.documentation = new vscode.MarkdownString(el.description);
                    item.detail = "AXML Element";
                    completions.push(item);
                }

                // Standard Properties
                for (const prop of PROPERTIES) {
                    const item = new vscode.CompletionItem(prop.name, vscode.CompletionItemKind.Property);
                    if (prop.snippet) {
                        item.insertText = new vscode.SnippetString(prop.snippet);
                    } else {
                        item.insertText = new vscode.SnippetString(`${prop.name}: $0`);
                    }
                    item.documentation = new vscode.MarkdownString(prop.description);
                    item.detail = "AXML Property";
                    completions.push(item);
                }

                // Events
                for (const evt of EVENTS) {
                    const item = new vscode.CompletionItem(evt.name, vscode.CompletionItemKind.Event);
                    item.insertText = new vscode.SnippetString(`${evt.name}: $0`);
                    item.documentation = new vscode.MarkdownString(evt.description);
                    item.detail = "AXML Event";
                    completions.push(item);
                }

                // Custom Properties Completion
                for (const custom of customProps) {
                    const item = new vscode.CompletionItem(custom, vscode.CompletionItemKind.Property);
                    item.insertText = new vscode.SnippetString(`${custom}: $0`);
                    item.detail = "Custom Property (from settings)";
                    completions.push(item);
                }

                return completions;
            }
        },
        ' ', '{' // trigger on space or {
    );

    // 2. Document Symbol Provider (Outline & Graph)
    const symbolProvider = vscode.languages.registerDocumentSymbolProvider('axml', {
        provideDocumentSymbols(document: vscode.TextDocument, token: vscode.CancellationToken) {
            const symbols: vscode.DocumentSymbol[] = [];
            const stack: { indent: number, symbol: vscode.DocumentSymbol }[] = [];

            for (let i = 0; i < document.lineCount; i++) {
                const line = document.lineAt(i);
                const text = line.text;
                if (text.trim().length === 0 || text.trim().startsWith('#')) continue;

                const indent = getIndentLength(text);

                // Match Elements: Grid:, StackPanel (MyPanel):
                const elMatch = text.match(/^\\s*([a-zA-Z0-9_\\.]+)(?:\\s*\\(([^)]+)\\))?\\s*:/);
                if (elMatch) {
                    // Check if it's a property vs element. Elements usually have uppercase first letter, or an ID.
                    const isProp = !elMatch[2] && PROPERTIES.some(p => p.name === elMatch[1]) && !ELEMENTS.some(e => e.name === elMatch[1]);
                    if (!isProp) {
                        const name = elMatch[1];
                        const id = elMatch[2] ? ` (${elMatch[2]})` : '';
                        const detail = id ? `ID: ${elMatch[2]}` : '';

                        const symbol = new vscode.DocumentSymbol(
                            name + id,
                            detail,
                            vscode.SymbolKind.Class,
                            line.range,
                            line.range
                        );

                        while (stack.length > 0 && stack[stack.length - 1].indent >= indent) {
                            stack.pop();
                        }

                        if (stack.length === 0) {
                            symbols.push(symbol);
                        } else {
                            stack[stack.length - 1].symbol.children.push(symbol);
                        }

                        stack.push({ indent, symbol });
                    }
                }
            }
            return symbols;
        }
    });

    // 3. Folding Range Provider (Auto-collapse)
    const foldingProvider = vscode.languages.registerFoldingRangeProvider('axml', {
        provideFoldingRanges(document: vscode.TextDocument, context: vscode.FoldingContext, token: vscode.CancellationToken) {
            const ranges: vscode.FoldingRange[] = [];
            const stack: { line: number, indent: number }[] = [];

            for (let i = 0; i < document.lineCount; i++) {
                const line = document.lineAt(i).text;
                if (line.trim().length === 0) continue;

                const indent = getIndentLength(line);

                while (stack.length > 0 && stack[stack.length - 1].indent >= indent) {
                    const popped = stack.pop()!;
                    if (i - 1 > popped.line) {
                        ranges.push(new vscode.FoldingRange(popped.line, i - 1, vscode.FoldingRangeKind.Region));
                    }
                }

                // If line ends with colon, it starts a block
                if (line.trim().endsWith(':')) {
                    stack.push({ line: i, indent });
                }
            }

            // Close remaining
            while (stack.length > 0) {
                const popped = stack.pop()!;
                if (document.lineCount - 1 > popped.line) {
                    ranges.push(new vscode.FoldingRange(popped.line, document.lineCount - 1, vscode.FoldingRangeKind.Region));
                }
            }

            return ranges;
        }
    });

    // 4. Color Picker Provider
    const colorProvider = vscode.languages.registerColorProvider('axml', {
        provideDocumentColors(document: vscode.TextDocument, token: vscode.CancellationToken) {
            const colors: vscode.ColorInformation[] = [];

            // Hex Regex
            const hexRegex = /#([0-9a-fA-F]{6,8})/g;
            for (let i = 0; i < document.lineCount; i++) {
                const line = document.lineAt(i);
                let match;
                while ((match = hexRegex.exec(line.text)) !== null) {
                    const hex = match[1];
                    const range = new vscode.Range(i, match.index, i, match.index + match[0].length);
                    let a = 1.0, r = 0, g = 0, b = 0;
                    if (hex.length === 6) {
                        r = parseInt(hex.substr(0, 2), 16) / 255; g = parseInt(hex.substr(2, 2), 16) / 255; b = parseInt(hex.substr(4, 2), 16) / 255;
                    } else if (hex.length === 8) {
                        a = parseInt(hex.substr(0, 2), 16) / 255; r = parseInt(hex.substr(2, 2), 16) / 255; g = parseInt(hex.substr(4, 2), 16) / 255; b = parseInt(hex.substr(6, 2), 16) / 255;
                    }
                    colors.push(new vscode.ColorInformation(range, new vscode.Color(r, g, b, a)));
                }

                // DynamicResource Regex
                const drRegex = /\{DynamicResource\s+([a-zA-Z0-9_]+)\}/g;
                let drMatch;
                while ((drMatch = drRegex.exec(line.text)) !== null) {
                    const resName = drMatch[1];
                    const resInfo = RESOURCES.find(r => r.name === resName);
                    if (resInfo && resInfo.hex) {
                        const hex = resInfo.hex.replace('#', '');
                        const range = new vscode.Range(i, drMatch.index, i, drMatch.index + drMatch[0].length);
                        let a = 1.0, r = 0, g = 0, b = 0;
                        if (hex.length === 6) {
                            r = parseInt(hex.substr(0, 2), 16) / 255; g = parseInt(hex.substr(2, 2), 16) / 255; b = parseInt(hex.substr(4, 2), 16) / 255;
                        } else if (hex.length === 8) {
                            a = parseInt(hex.substr(0, 2), 16) / 255; r = parseInt(hex.substr(2, 2), 16) / 255; g = parseInt(hex.substr(4, 2), 16) / 255; b = parseInt(hex.substr(6, 2), 16) / 255;
                        }
                        colors.push(new vscode.ColorInformation(range, new vscode.Color(r, g, b, a)));
                    }
                }
            }
            return colors;
        },
        provideColorPresentations(color: vscode.Color, context: { document: vscode.TextDocument, range: vscode.Range }) {
            const toHex = (c: number) => Math.round(c * 255).toString(16).padStart(2, '0').toUpperCase();
            let hexStr = "#";
            if (color.alpha < 1.0) hexStr += toHex(color.alpha);
            hexStr += toHex(color.red) + toHex(color.green) + toHex(color.blue);
            return [new vscode.ColorPresentation(hexStr)];
        }
    });

    // 5. Definition Provider (Event Linking)
    const definitionProvider = vscode.languages.registerDefinitionProvider('axml', {
        async provideDefinition(document: vscode.TextDocument, position: vscode.Position, token: vscode.CancellationToken) {
            const line = document.lineAt(position.line);
            const match = line.text.match(/^\s*On[a-zA-Z]+\s*:\s*([a-zA-Z0-9_]+)$/);
            if (match) {
                const funcName = match[1];
                const startIdx = line.text.lastIndexOf(funcName);
                if (position.character >= startIdx && position.character <= startIdx + funcName.length) {

                    const files = await vscode.workspace.findFiles('**/*.ahk', '**/node_modules/**', 100);
                    const locations: vscode.Location[] = [];
                    const funcRegex = new RegExp(`^\\s*${funcName}\\s*\\(`, 'i');

                    for (const file of files) {
                        try {
                            const doc = await vscode.workspace.openTextDocument(file);
                            for (let i = 0; i < doc.lineCount; i++) {
                                if (funcRegex.test(doc.lineAt(i).text)) {
                                    locations.push(new vscode.Location(file, new vscode.Position(i, 0)));
                                }
                            }
                        } catch (e) { }
                    }

                    if (locations.length > 0) {
                        return locations;
                    }

                    vscode.commands.executeCommand('workbench.action.findInFiles', {
                        query: funcName,
                        isCaseSensitive: false,
                        matchWholeWord: true,
                        filesToInclude: "*.ahk"
                    });

                    return null;
                }
            }
            return null;
        }
    });

    // 6. Diagnostics (Linter) & Quick Fixes
    const diagnosticCollection = vscode.languages.createDiagnosticCollection('axml');
    function updateDiagnostics(document: vscode.TextDocument) {
        if (document.languageId !== 'axml') return;

        const diagnostics: vscode.Diagnostic[] = [];
        const lines = document.getText().split('\\n');

        for (let i = 0; i < lines.length; i++) {
            const line = lines[i];
            const match = line.match(/^\\s*([a-zA-Z0-9_\\.]+)\\s*:/);
            if (match) {
                const propName = match[1];
                if (commonFixes[propName]) {
                    const correctProp = commonFixes[propName];
                    const startIdx = line.indexOf(propName);
                    const range = new vscode.Range(i, startIdx, i, startIdx + propName.length);

                    const diagnostic = new vscode.Diagnostic(
                        range,
                        `'${propName}' is not a standard property. Did you mean '${correctProp}'?`,
                        vscode.DiagnosticSeverity.Warning
                    );
                    diagnostic.code = "axml-common-fix";
                    diagnostics.push(diagnostic);
                }
            }
        }
        diagnosticCollection.set(document.uri, diagnostics);
    }

    vscode.workspace.onDidChangeTextDocument(e => updateDiagnostics(e.document), null, context.subscriptions);
    vscode.workspace.onDidOpenTextDocument(doc => updateDiagnostics(doc), null, context.subscriptions);
    if (vscode.window.activeTextEditor) {
        updateDiagnostics(vscode.window.activeTextEditor.document);
    }

    const quickFixProvider = vscode.languages.registerCodeActionsProvider('axml', {
        provideCodeActions(document: vscode.TextDocument, range: vscode.Range, context: vscode.CodeActionContext) {
            const actions: vscode.CodeAction[] = [];
            for (const diagnostic of context.diagnostics) {
                if (diagnostic.code === "axml-common-fix") {
                    const word = document.getText(diagnostic.range);
                    const correctProp = commonFixes[word];
                    if (correctProp) {
                        const fix = new vscode.CodeAction(`Change to '${correctProp}'`, vscode.CodeActionKind.QuickFix);
                        fix.edit = new vscode.WorkspaceEdit();
                        fix.edit.replace(document.uri, diagnostic.range, correctProp);
                        fix.diagnostics = [diagnostic];
                        fix.isPreferred = true;
                        actions.push(fix);
                    }
                }
            }
            return actions;
        }
    });

    // 7. Hover Provider
    const hoverProvider = vscode.languages.registerHoverProvider('axml', {
        provideHover(document: vscode.TextDocument, position: vscode.Position) {
            const range = document.getWordRangeAtPosition(position, /[a-zA-Z0-9_\\.]+/);
            if (!range) return null;

            const word = document.getText(range);

            const el = ELEMENTS.find(e => e.name === word);
            if (el) return new vscode.Hover(new vscode.MarkdownString(`**${el.name}**\n\n${el.description}`));

            const prop = PROPERTIES.find(e => e.name === word);
            if (prop) {
                const md = new vscode.MarkdownString(`**${prop.name}**\n\n${prop.description}`);
                md.isTrusted = true;

                if (['Margin', 'Padding', 'BorderThickness', 'CornerRadius'].includes(prop.name)) {
                    const uri = `command:axml.generateMargin?${encodeURIComponent(JSON.stringify([document.uri.toString(), position.line]))}`;
                    md.appendMarkdown(`\n\n---\n[🪄 Generate Value](${uri})`);
                }

                if (['Background', 'Foreground', 'BorderBrush'].includes(prop.name)) {
                    const uri = `command:axml.chooseThemeColor?${encodeURIComponent(JSON.stringify([document.uri.toString(), position.line]))}`;
                    md.appendMarkdown(`\n\n---\n[🎨 Choose Theme Color](${uri})`);
                }

                return new vscode.Hover(md);
            }

            const evt = EVENTS.find(e => e.name === word);
            if (evt) return new vscode.Hover(new vscode.MarkdownString(`**${evt.name}**\n\n${evt.description}`));

            const res = RESOURCES.find(e => e.name === word);
            if (res) return new vscode.Hover(new vscode.MarkdownString(`**${res.name}**\n\n${res.description}\n*(DynamicResource)*`));

            return null;
        }
    });

    // 8. Interactive Commands
    const cmdMargin = vscode.commands.registerCommand('axml.generateMargin', async (args) => {
        if (!args || args.length < 2) return;
        const uri = vscode.Uri.parse(args[0]);
        const line = args[1];

        const editor = vscode.window.activeTextEditor;
        if (!editor || editor.document.uri.toString() !== uri.toString()) return;

        const uniform = await vscode.window.showInputBox({ prompt: "Enter Uniform Value (or press Enter to specify individual sides)" });
        let result = "";

        if (uniform) {
            result = uniform;
        } else {
            const left = await vscode.window.showInputBox({ prompt: "Left" }) || "0";
            const top = await vscode.window.showInputBox({ prompt: "Top" }) || "0";
            const right = await vscode.window.showInputBox({ prompt: "Right" }) || "0";
            const bottom = await vscode.window.showInputBox({ prompt: "Bottom" }) || "0";
            result = `${left},${top},${right},${bottom}`;
        }

        const lineText = editor.document.lineAt(line).text;
        const match = lineText.match(/^(\s*[a-zA-Z0-9_\.]+\s*:\s*).*$/);
        if (match) {
            const replaceRange = new vscode.Range(line, match[1].length, line, lineText.length);
            editor.edit(editBuilder => {
                editBuilder.replace(replaceRange, `"${result}"`);
            });
        }
    });

    const cmdColor = vscode.commands.registerCommand('axml.chooseThemeColor', async (args) => {
        if (!args || args.length < 2) return;
        const uri = vscode.Uri.parse(args[0]);
        const line = args[1];

        const editor = vscode.window.activeTextEditor;
        if (!editor || editor.document.uri.toString() !== uri.toString()) return;

        const items = RESOURCES.map(r => ({ label: r.name, description: r.hex || "Theme Color" }));
        const picked = await vscode.window.showQuickPick(items, { placeHolder: "Select a Theme Color..." });

        if (picked) {
            const lineText = editor.document.lineAt(line).text;
            const match = lineText.match(/^(\s*[a-zA-Z0-9_\.]+\s*:\s*).*$/);
            if (match) {
                const replaceRange = new vscode.Range(line, match[1].length, line, lineText.length);
                editor.edit(editBuilder => {
                    editBuilder.replace(replaceRange, `"{DynamicResource ${picked.label}}"`);
                });
            }
        }
    });

    context.subscriptions.push(
        completionProvider,
        symbolProvider,
        foldingProvider,
        colorProvider,
        definitionProvider,
        diagnosticCollection,
        quickFixProvider,
        hoverProvider,
        cmdMargin,
        cmdColor
    );
}

export function deactivate() { }
