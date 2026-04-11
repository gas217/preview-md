import Foundation

private final class HTMLTemplateBundleLocator {}

enum HTMLTemplate {
    static let mermaidScript: String = {
        let bundle = Bundle(for: HTMLTemplateBundleLocator.self)
        guard let url = bundle.url(forResource: "mermaid.min", withExtension: "js"),
              let data = try? Data(contentsOf: url),
              let str = String(data: data, encoding: .utf8) else {
            return ""
        }
        return str
    }()

    static func build(frontmatter: String, content: String, hasMermaid: Bool = false) -> String {
        let nonce = generateNonce()
        let mermaidTag: String
        if hasMermaid && !mermaidScript.isEmpty {
            mermaidTag = """
            <script nonce="\(nonce)">
            \(mermaidScript)
            </script>
            <script nonce="\(nonce)">
            \(mermaidInitScript)
            </script>
            """
        } else {
            mermaidTag = ""
        }
        return """
        <!DOCTYPE html>
        <html>
        <head>
        <meta charset="utf-8">
        <meta http-equiv="Content-Security-Policy" content="default-src 'none'; style-src 'unsafe-inline'; script-src 'nonce-\(nonce)'; img-src file: data:;">
        <style>
        \(css)
        </style>
        </head>
        <body>
        \(frontmatter)
        <article class="markdown-body">
        \(content)
        </article>
        <script nonce="\(nonce)">
        \(highlightScript)
        \(autolinkScript)
        document.body.setAttribute('tabindex', '0');
        document.body.focus();
        </script>
        \(mermaidTag)
        </body>
        </html>
        """
    }

    private static func generateNonce() -> String {
        var bytes = [UInt8](repeating: 0, count: 16)
        _ = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        return Data(bytes).base64EncodedString()
    }

    // MARK: - CSS Theme (embedded for reliability)

    static let css = """
    /* PreviewMD Theme — Light & Dark */

    :root {
        --text: #1d1d1f;
        --text-secondary: #6e6e73;
        --bg: #ffffff;
        --bg-secondary: #f5f5f7;
        --border: #d2d2d7;
        --accent: #0071e3;
        --link: #0066cc;
        --table-stripe: #f9f9fb;
        --badge-green-bg: #e3f8e8;
        --badge-green-text: #1a7a2e;
        --badge-blue-bg: #e0f0ff;
        --badge-blue-text: #0055b3;
        --badge-red-bg: #ffe5e5;
        --badge-red-text: #cc1100;
        --badge-yellow-bg: #fff8e0;
        --badge-yellow-text: #946c00;
        --badge-orange-bg: #fff0e0;
        --badge-orange-text: #b35c00;
        --badge-gray-bg: #f0f0f2;
        --tag-bg: #e8e8ed;
        --tag-text: #48484a;
        --hl-keyword: #d73a49;
        --hl-string: #032f62;
        --hl-comment: #6a737d;
        --hl-number: #005cc5;
    }

    @media (prefers-color-scheme: dark) {
        :root {
            --text: #f5f5f7;
            --text-secondary: #a1a1a6;
            --bg: #1d1d1f;
            --bg-secondary: #2c2c2e;
            --border: #48484a;
            --accent: #2997ff;
            --link: #64b5f6;
            --table-stripe: #252527;
            --badge-green-bg: #1a3a1f;
            --badge-green-text: #6ee07a;
            --badge-blue-bg: #0d2844;
            --badge-blue-text: #64b5f6;
            --badge-red-bg: #3a1515;
            --badge-red-text: #ff6b6b;
            --badge-yellow-bg: #3a3015;
            --badge-yellow-text: #ffd666;
            --badge-orange-bg: #3a2815;
            --badge-orange-text: #ffb366;
            --badge-gray-bg: #38383a;
            --tag-bg: #38383a;
            --tag-text: #c7c7cc;
            --hl-keyword: #ff7b72;
            --hl-string: #a5d6ff;
            --hl-comment: #8b949e;
            --hl-number: #79c0ff;
        }
        ::selection {
            background: rgba(41, 151, 255, 0.35);
        }
    }

    * {
        margin: 0;
        padding: 0;
        box-sizing: border-box;
    }

    ::selection {
        background: rgba(0, 113, 227, 0.25);
    }

    html {
        scroll-behavior: smooth;
    }

    body {
        font-family: -apple-system, sans-serif;
        font-size: 15px;
        line-height: 1.6;
        color: var(--text);
        background: var(--bg);
        padding: 24px 32px;
        max-width: 860px;
        margin: 0 auto;
        -webkit-font-smoothing: antialiased;
    }

    /* Frontmatter */

    .frontmatter {
        background: var(--bg-secondary);
        border: 1px solid var(--border);
        border-radius: 10px;
        padding: 20px 24px;
        margin-bottom: 28px;
    }

    .fm-title {
        font-size: 1.75em;
        font-weight: 700;
        letter-spacing: -0.02em;
        margin-bottom: 10px;
        line-height: 1.2;
    }

    .fm-meta {
        display: flex;
        flex-wrap: wrap;
        gap: 8px;
        align-items: center;
        margin-bottom: 12px;
    }

    .fm-badge {
        display: inline-block;
        font-size: 12px;
        font-weight: 600;
        padding: 3px 10px;
        border-radius: 12px;
        text-transform: capitalize;
    }

    .badge-green  { background: var(--badge-green-bg);  color: var(--badge-green-text); }
    .badge-blue   { background: var(--badge-blue-bg);   color: var(--badge-blue-text); }
    .badge-red    { background: var(--badge-red-bg);     color: var(--badge-red-text); }
    .badge-yellow { background: var(--badge-yellow-bg);  color: var(--badge-yellow-text); }
    .badge-orange { background: var(--badge-orange-bg);  color: var(--badge-orange-text); }
    .badge-gray   { background: var(--badge-gray-bg);   color: var(--text-secondary); }

    .fm-date {
        font-size: 13px;
        color: var(--text-secondary);
    }

    .fm-tag {
        display: inline-block;
        font-size: 12px;
        font-weight: 500;
        padding: 2px 8px;
        border-radius: 4px;
        background: var(--tag-bg);
        color: var(--tag-text);
    }

    .fm-fields {
        display: grid;
        grid-template-columns: auto 1fr;
        gap: 4px 16px;
        font-size: 13px;
        margin-top: 8px;
    }

    .fm-fields dt {
        color: var(--text-secondary);
        font-weight: 500;
    }

    .fm-fields dd {
        overflow: hidden;
        text-overflow: ellipsis;
        display: -webkit-box;
        -webkit-line-clamp: 3;
        -webkit-box-orient: vertical;
    }

    /* Markdown Content */

    .markdown-body {
        line-height: 1.65;
    }

    .markdown-body > *:first-child {
        margin-top: 0;
    }

    .markdown-body :is(h1, h2, h3, h4, h5, h6) {
        margin-top: 1.5em;
        margin-bottom: 0.5em;
        font-weight: 600;
        letter-spacing: -0.01em;
        line-height: 1.25;
    }

    .markdown-body h1 { font-size: 1.8em; font-weight: 700; letter-spacing: -0.02em; }
    .markdown-body h2 { font-size: 1.4em; border-bottom: 1px solid var(--border); padding-bottom: 0.3em; }
    .markdown-body h3 { font-size: 1.15em; }
    .markdown-body h5 { font-size: 0.9em; }
    .markdown-body h6 { font-size: 0.85em; color: var(--text-secondary); }

    .markdown-body p {
        margin-bottom: 1em;
        overflow-wrap: break-word;
    }

    .markdown-body a {
        color: var(--link);
        text-decoration: none;
        word-break: break-all;
    }

    .markdown-body a:hover {
        text-decoration: underline;
        text-underline-offset: 2px;
    }

    .markdown-body strong {
        font-weight: 600;
    }

    /* Lists */

    .markdown-body ul,
    .markdown-body ol {
        margin-bottom: 1em;
        padding-left: 2em;
    }

    .markdown-body li {
        margin-bottom: 0.25em;
    }

    .markdown-body li > p {
        margin-bottom: 0.5em;
    }

    .markdown-body :is(ul, ol) :is(ul, ol) {
        margin-bottom: 0;
    }

    /* Task Lists */

    .task-list {
        list-style: none;
        padding-left: 0;
    }

    .task-list-item {
        position: relative;
        padding-left: 1.75em;
    }

    .task-list-item input[type="checkbox"] {
        position: absolute;
        left: 0;
        top: 0.35em;
        margin: 0;
        accent-color: var(--accent);
    }

    .task-list-item p {
        display: inline;
    }

    .task-list-item.done {
        color: var(--text-secondary);
    }

    .task-list-item.done > p {
        text-decoration: line-through;
        opacity: 0.7;
    }

    /* Code */

    .markdown-body code {
        font-family: ui-monospace, monospace;
        font-size: 0.88em;
        background: var(--bg-secondary);
        color: var(--text);
        padding: 0.15em 0.4em;
        border-radius: 4px;
    }

    .markdown-body pre {
        background: var(--bg-secondary);
        border: 1px solid var(--border);
        border-radius: 8px;
        padding: 16px;
        overflow-x: auto;
        margin-bottom: 1em;
        line-height: 1.45;
        tab-size: 4;
        position: relative;
    }

    .markdown-body pre code {
        background: none; padding: 0; border-radius: 0;
        font-size: 13px;
    }

    .markdown-body pre code[class*="language-"]::before {
        content: attr(data-lang);
        position: absolute;
        top: 6px;
        right: 10px;
        font: 11px -apple-system, sans-serif;
        color: var(--text-secondary);
        opacity: 0.6;
        pointer-events: none;
    }

    /* Syntax Highlighting */
    .hljs-keyword { color: var(--hl-keyword); font-weight: 600; }
    .hljs-string  { color: var(--hl-string); }
    .hljs-comment { color: var(--hl-comment); font-style: italic; }
    .hljs-number  { color: var(--hl-number); }

    /* Blockquotes */

    .markdown-body blockquote {
        border-left: 3px solid var(--accent);
        color: var(--text-secondary);
        padding: 0.5em 1em;
        margin: 0 0 1em 0;
    }

    .markdown-body blockquote p:last-child {
        margin-bottom: 0;
    }

    /* Tables */

    .markdown-body .table-wrap {
        overflow-x: auto;
        margin-bottom: 1em;
    }

    .markdown-body table {
        width: 100%;
        border-collapse: collapse;
        font-size: 14px;
    }

    .markdown-body th,
    .markdown-body td {
        border: 1px solid var(--border);
        padding: 8px 12px;
        text-align: left;
    }

    .markdown-body th {
        background: var(--bg-secondary);
        font-weight: 600;
        font-size: 13px;
    }

    .markdown-body tbody tr:nth-child(even) {
        background: var(--table-stripe);
    }

    .markdown-body tbody tr:hover {
        background: var(--bg-secondary);
    }

    /* Horizontal Rule */

    .markdown-body hr {
        border: none;
        border-top: 1px solid var(--border);
        margin: 2em 0;
    }

    /* Images */

    .markdown-body img {
        max-width: 100%;
        height: auto;
        border-radius: 6px;
    }

    /* Mermaid diagrams */
    .mermaid-block {
        margin: 1em 0;
        padding: 16px;
        background: var(--bg-secondary);
        border: 1px solid var(--border);
        border-radius: 8px;
        text-align: center;
        overflow-x: auto;
    }
    .mermaid-block[data-mermaid-src]::before {
        content: "Rendering diagram…";
        color: var(--text-secondary);
        font-size: 13px;
        font-style: italic;
    }
    .mermaid-block svg {
        max-width: 100%;
        height: auto;
    }
    .mermaid-error {
        color: var(--badge-red-text);
        background: var(--badge-red-bg);
        padding: 8px 12px;
        border-radius: 4px;
        text-align: left;
        font-size: 13px;
        margin-bottom: 8px;
    }
    .mermaid-error + pre {
        text-align: left;
        background: var(--bg);
        border: 1px solid var(--border);
        border-radius: 4px;
        padding: 8px 12px;
        font-size: 12px;
        overflow-x: auto;
    }

    /* Admonitions (GitHub-style) */
    [class^="adm-"] { border-radius: 6px; padding: 12px 16px; }
    .adm-note, .adm-important { border-color: var(--accent); background: var(--badge-blue-bg); }
    .adm-tip       { border-color: var(--badge-green-text); background: var(--badge-green-bg); }
    .adm-warning   { border-color: var(--badge-yellow-text); background: var(--badge-yellow-bg); }
    .adm-caution   { border-color: var(--badge-red-text); background: var(--badge-red-bg); }

    /* Strikethrough */
    .markdown-body del {
        text-decoration: line-through;
        opacity: 0.65;
    }

    /* Print */
    @media print {
        body { background: white; color: black; max-width: none; padding: 0; }
        .frontmatter { border-color: #ccc; background: #f9f9f9; }
        .markdown-body pre { border-color: #ccc; }
        .markdown-body a { color: #0066cc; }
        .markdown-body pre code[class*="language-"]::before { display: none; }
    }
    """

    // MARK: - Syntax Highlighting Script (embedded)

    static let highlightScript = """
    (function() {
        const keywords = {
            'swift': /\\b(import|func|var|let|class|struct|enum|protocol|extension|return|if|else|guard|switch|case|default|for|while|repeat|break|continue|throw|throws|try|catch|async|await|self|Self|super|nil|true|false|public|private|internal|open|fileprivate|static|override|init|deinit|where|in|as|is|typealias|associatedtype|some|any|weak|unowned|lazy|mutating|nonmutating|convenience|required|final|inout|defer|do|willSet|didSet|get|set)\\b/g,
            'python': /\\b(import|from|def|class|return|if|elif|else|for|while|break|continue|try|except|finally|raise|with|as|pass|yield|lambda|and|or|not|in|is|True|False|None|self|async|await|print|range|len|type|list|dict|set|tuple|str|int|float|bool)\\b/g,
            'javascript': /\\b(import|export|from|function|const|let|var|return|if|else|for|while|do|break|continue|switch|case|default|try|catch|finally|throw|new|delete|typeof|instanceof|this|class|extends|super|async|await|yield|true|false|null|undefined|of|in)\\b/g,
            'typescript': /\\b(import|export|from|function|const|let|var|return|if|else|for|while|do|break|continue|switch|case|default|try|catch|finally|throw|new|delete|typeof|instanceof|this|class|extends|super|async|await|yield|true|false|null|undefined|of|in|interface|type|enum|namespace|abstract|implements|readonly|private|protected|public|static|as|is|keyof|infer|never|unknown|any|void)\\b/g,
            'go': /\\b(package|import|func|var|const|type|struct|interface|return|if|else|for|range|switch|case|default|break|continue|go|defer|chan|select|map|make|new|append|len|cap|true|false|nil|error|string|int|float64|bool|byte|rune)\\b/g,
            'rust': /\\b(use|mod|fn|let|mut|const|static|struct|enum|impl|trait|return|if|else|for|while|loop|break|continue|match|pub|self|Self|super|crate|where|as|in|ref|move|async|await|true|false|Some|None|Ok|Err|Box|Vec|String|Option|Result|println|macro_rules)\\b/g,
            'ruby': /\\b(require|include|def|class|module|return|if|elsif|else|unless|while|until|for|do|end|begin|rescue|ensure|raise|yield|block_given|self|super|true|false|nil|and|or|not|in|then|puts|print|attr_accessor|attr_reader|attr_writer)\\b/g,
            'c': /\\b(auto|break|case|char|const|continue|default|do|double|else|enum|extern|float|for|goto|if|inline|int|long|register|restrict|return|short|signed|sizeof|static|struct|switch|typedef|union|unsigned|void|volatile|while|NULL|true|false|include|define|ifdef|ifndef|endif|pragma)\\b/g,
            'cpp': /\\b(auto|break|case|char|const|continue|default|do|double|else|enum|extern|float|for|goto|if|inline|int|long|register|return|short|signed|sizeof|static|struct|switch|typedef|union|unsigned|void|volatile|while|class|namespace|template|typename|using|virtual|override|public|private|protected|new|delete|throw|try|catch|nullptr|bool|true|false|const_cast|dynamic_cast|static_cast|reinterpret_cast|include|define|ifdef|ifndef|endif|pragma|constexpr|noexcept|decltype|auto|concept|requires|co_await|co_return|co_yield)\\b/g,
            'java': /\\b(abstract|assert|boolean|break|byte|case|catch|char|class|const|continue|default|do|double|else|enum|extends|final|finally|float|for|goto|if|implements|import|instanceof|int|interface|long|native|new|package|private|protected|public|return|short|static|strictfp|super|switch|synchronized|this|throw|throws|transient|try|void|volatile|while|true|false|null|var|record|sealed|permits|yield)\\b/g,
            'kotlin': /\\b(abstract|actual|annotation|as|break|by|catch|class|companion|const|constructor|continue|crossinline|data|do|else|enum|expect|external|false|final|finally|for|fun|get|if|import|in|infix|init|inline|inner|interface|internal|is|lateinit|noinline|null|object|open|operator|out|override|package|private|protected|public|reified|return|sealed|set|super|suspend|tailrec|this|throw|true|try|typealias|val|var|vararg|when|where|while)\\b/g,
            'php': /\\b(abstract|and|array|as|break|callable|case|catch|class|clone|const|continue|declare|default|die|do|echo|else|elseif|empty|enddeclare|endfor|endforeach|endif|endswitch|endwhile|eval|exit|extends|final|finally|fn|for|foreach|function|global|goto|if|implements|include|instanceof|insteadof|interface|isset|list|match|namespace|new|or|print|private|protected|public|readonly|require|return|static|switch|throw|trait|try|unset|use|var|while|xor|yield|true|false|null|self)\\b/g,
            'bash': /\\b(if|then|else|elif|fi|for|while|do|done|case|esac|function|return|local|export|source|echo|exit|test|cd|ls|grep|sed|awk|cat|mkdir|rm|cp|mv|chmod|chown|curl|wget|sudo|apt|brew|npm|git|docker)\\b/g,
            'sql': /\\b(SELECT|FROM|WHERE|INSERT|INTO|UPDATE|SET|DELETE|CREATE|DROP|ALTER|TABLE|INDEX|VIEW|JOIN|LEFT|RIGHT|INNER|OUTER|ON|AND|OR|NOT|IN|EXISTS|BETWEEN|LIKE|ORDER|BY|GROUP|HAVING|LIMIT|OFFSET|AS|NULL|IS|DISTINCT|UNION|ALL|COUNT|SUM|AVG|MIN|MAX|CASE|WHEN|THEN|ELSE|END|PRIMARY|KEY|FOREIGN|REFERENCES|CONSTRAINT|DEFAULT|VALUES)\\b/gi,
        };

        // Language aliases
        const aliases = {'sh': 'bash', 'shell': 'bash', 'zsh': 'bash', 'c++': 'cpp', 'cxx': 'cpp', 'objc': 'c', 'objective-c': 'c', 'kt': 'kotlin', 'py': 'python', 'js': 'javascript', 'ts': 'typescript', 'rs': 'rust', 'rb': 'ruby'};

        const cCommentSrc = '(\\/\\/.*$|\\/\\*[\\s\\S]*?\\*\\/)';
        const hashCmt = '(#.*$)';
        const commentSrc = {
            python: hashCmt, ruby: hashCmt, bash: hashCmt,
            php: '(\\/\\/.*$|\\/\\*[\\s\\S]*?\\*\\/|#.*$)',
            sql: '(--.*$|\\/\\*[\\s\\S]*?\\*\\/)',
        };
        const stringSrc = '("(?:[^"\\\\\\\\]|\\\\\\\\.)*"|' + "'(?:[^'\\\\\\\\]|\\\\\\\\.)*'" + '|`(?:[^`\\\\\\\\]|\\\\\\\\.)*`)';
        const numberRegex = /\\b(\\d+\\.?\\d*(?:e[+-]?\\d+)?|0x[0-9a-fA-F]+|0b[01]+|0o[0-7]+)\\b/g;

        function esc(s) {
            return s.replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;');
        }

        document.querySelectorAll('pre code[class*="language-"]').forEach(function(block) {
            const langMatch = block.className.match(/language-(\\w+)/);
            if (!langMatch) return;
            const lang = aliases[langMatch[1].toLowerCase()] || langMatch[1].toLowerCase();
            if (!keywords[lang]) return;

            const raw = block.textContent;
            const tokens = [];

            // Pick comment pattern based on language
            var cmtSrc = commentSrc[lang] || cCommentSrc;
            const combined = new RegExp(cmtSrc + '|' + stringSrc, 'gm');

            let lastIdx = 0;
            let match;
            combined.lastIndex = 0;
            while ((match = combined.exec(raw)) !== null) {
                if (match.index > lastIdx) {
                    tokens.push({type: 'code', text: raw.slice(lastIdx, match.index)});
                }
                if (match[1]) {
                    tokens.push({type: 'comment', text: match[0]});
                } else {
                    tokens.push({type: 'string', text: match[0]});
                }
                lastIdx = combined.lastIndex;
            }
            if (lastIdx < raw.length) {
                tokens.push({type: 'code', text: raw.slice(lastIdx)});
            }

            const kw = keywords[lang];
            let result = tokens.map(function(t) {
                const escaped = esc(t.text);
                if (t.type === 'comment') return '<span class="hljs-comment">' + escaped + '</span>';
                if (t.type === 'string') return '<span class="hljs-string">' + escaped + '</span>';
                // Highlight keywords and numbers in code tokens
                return escaped
                    .replace(kw, '<span class="hljs-keyword">$1</span>')
                    .replace(numberRegex, '<span class="hljs-number">$1</span>');
            }).join('');

            block.innerHTML = result;
        });
    })();
    """

    // MARK: - Autolink Script

    static let autolinkScript = """
    (function() {
        // Auto-link bare URLs in text nodes that aren't already inside links or code
        const urlRegex = /(https?:\\/\\/[^\\s<>]+)/g;
        const article = document.querySelector('.markdown-body');
        if (!article) return;

        function isBalanced(s, open, close) {
            return (s.match(open) || []).length >= (s.match(close) || []).length;
        }
        const skip = new Set(['A', 'CODE', 'PRE', 'SCRIPT']);
        function hasSkipAncestor(node) {
            for (var p = node.parentElement; p && p !== article; p = p.parentElement) {
                if (skip.has(p.tagName)) return true;
            }
            return false;
        }
        const walker = document.createTreeWalker(article, NodeFilter.SHOW_TEXT, {
            acceptNode: function(node) {
                if (!node.parentElement || hasSkipAncestor(node)) return NodeFilter.FILTER_REJECT;
                urlRegex.lastIndex = 0;
                return urlRegex.test(node.textContent) ? NodeFilter.FILTER_ACCEPT : NodeFilter.FILTER_REJECT;
            }
        });

        const nodes = [];
        while (walker.nextNode()) nodes.push(walker.currentNode);

        nodes.forEach(function(node) {
            const frag = document.createDocumentFragment();
            const text = node.textContent;
            let lastIndex = 0;
            urlRegex.lastIndex = 0;
            let match;
            while ((match = urlRegex.exec(text)) !== null) {
                var url = match[1];
                var trailed = '';
                while (url.length > 0 && /[)\\].,;:!?'"]$/.test(url)) {
                    var ch = url.slice(-1);
                    if (ch === ')' && isBalanced(url, /\\(/g, /\\)/g)) break;
                    if (ch === ']' && isBalanced(url, /\\[/g, /\\]/g)) break;
                    trailed = ch + trailed;
                    url = url.slice(0, -1);
                }
                if (match.index > lastIndex) {
                    frag.appendChild(document.createTextNode(text.slice(lastIndex, match.index)));
                }
                const a = document.createElement('a');
                a.href = url;
                a.textContent = url;
                frag.appendChild(a);
                if (trailed) {
                    frag.appendChild(document.createTextNode(trailed));
                }
                lastIndex = urlRegex.lastIndex;
            }
            if (lastIndex < text.length) {
                frag.appendChild(document.createTextNode(text.slice(lastIndex)));
            }
            node.parentNode.replaceChild(frag, node);
        });
    })();
    """

    // MARK: - Mermaid Init Script

    static let mermaidInitScript = """
    (function() {
        if (typeof mermaid === 'undefined') return;
        var dark = window.matchMedia && window.matchMedia('(prefers-color-scheme: dark)').matches;
        mermaid.initialize({
            startOnLoad: false,
            securityLevel: 'strict',
            theme: dark ? 'dark' : 'default',
            fontFamily: '-apple-system, sans-serif'
        });
        var blocks = document.querySelectorAll('.mermaid-block[data-mermaid-src]');
        blocks.forEach(function(el, i) {
            var src = el.dataset.mermaidSrc;
            try {
                mermaid.render('mermaid-svg-' + i, src).then(function(result) {
                    el.innerHTML = result.svg;
                    el.removeAttribute('data-mermaid-src');
                }).catch(function(err) {
                    el.innerHTML = '<div class="mermaid-error"><strong>Mermaid error:</strong> ' +
                        (err && err.message ? err.message : String(err)) +
                        '</div><pre>' +
                        src.replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;') +
                        '</pre>';
                });
            } catch (err) {
                el.innerHTML = '<div class="mermaid-error"><strong>Mermaid error:</strong> ' +
                    (err && err.message ? err.message : String(err)) + '</div>';
            }
        });
    })();
    """
}
