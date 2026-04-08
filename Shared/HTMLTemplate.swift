import Foundation

enum HTMLTemplate {
    static func build(frontmatter: String, content: String) -> String {
        return """
        <!DOCTYPE html>
        <html>
        <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <style>
        \(css)
        </style>
        </head>
        <body>
        \(frontmatter)
        <article class="markdown-body">
        \(content)
        </article>
        <script>
        \(highlightScript)
        \(autolinkScript)
        </script>
        </body>
        </html>
        """
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
        --code-bg: #f5f5f7;
        --code-text: #1d1d1f;
        --blockquote-border: #d2d2d7;
        --blockquote-text: #6e6e73;
        --table-border: #d2d2d7;
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
        --badge-gray-text: #6e6e73;
        --tag-bg: #e8e8ed;
        --tag-text: #48484a;
        --fm-bg: #f5f5f7;
        --fm-border: #d2d2d7;
        --hr: #d2d2d7;
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
            --code-bg: #2c2c2e;
            --code-text: #f5f5f7;
            --blockquote-border: #48484a;
            --blockquote-text: #a1a1a6;
            --table-border: #48484a;
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
            --badge-gray-text: #a1a1a6;
            --tag-bg: #38383a;
            --tag-text: #c7c7cc;
            --fm-bg: #2c2c2e;
            --fm-border: #48484a;
            --hr: #48484a;
        }
    }

    * {
        margin: 0;
        padding: 0;
        box-sizing: border-box;
    }

    body {
        font-family: -apple-system, BlinkMacSystemFont, 'SF Pro Text', 'Helvetica Neue', sans-serif;
        font-size: 15px;
        line-height: 1.6;
        color: var(--text);
        background: var(--bg);
        padding: 24px 32px;
        max-width: 860px;
        margin: 0 auto;
        -webkit-font-smoothing: antialiased;
        -moz-osx-font-smoothing: grayscale;
    }

    /* Frontmatter */

    .frontmatter {
        background: var(--fm-bg);
        border: 1px solid var(--fm-border);
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
    .badge-gray   { background: var(--badge-gray-bg);   color: var(--badge-gray-text); }

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
        text-transform: capitalize;
    }

    .fm-fields dd {
        color: var(--text);
    }

    /* Markdown Content */

    .markdown-body {
        line-height: 1.65;
    }

    .markdown-body > *:first-child {
        margin-top: 0;
    }

    .markdown-body h1,
    .markdown-body h2,
    .markdown-body h3,
    .markdown-body h4,
    .markdown-body h5,
    .markdown-body h6 {
        margin-top: 1.5em;
        margin-bottom: 0.5em;
        font-weight: 600;
        letter-spacing: -0.01em;
        line-height: 1.25;
    }

    .markdown-body h1 { font-size: 1.8em; font-weight: 700; letter-spacing: -0.02em; }
    .markdown-body h2 { font-size: 1.4em; border-bottom: 1px solid var(--border); padding-bottom: 0.3em; }
    .markdown-body h3 { font-size: 1.15em; }
    .markdown-body h4 { font-size: 1em; }
    .markdown-body h5 { font-size: 0.9em; }
    .markdown-body h6 { font-size: 0.85em; color: var(--text-secondary); }

    .markdown-body p {
        margin-bottom: 1em;
    }

    .markdown-body a {
        color: var(--link);
        text-decoration: none;
    }

    .markdown-body a:hover {
        text-decoration: underline;
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

    .markdown-body ul ul,
    .markdown-body ol ol,
    .markdown-body ul ol,
    .markdown-body ol ul {
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
        top: 0.3em;
        margin: 0;
        accent-color: var(--accent);
    }

    .task-list-item.done {
        color: var(--text-secondary);
    }

    .task-list-item.done p {
        text-decoration: line-through;
        opacity: 0.7;
    }

    /* Code */

    .markdown-body code {
        font-family: 'SF Mono', 'Menlo', 'Monaco', 'Courier New', monospace;
        font-size: 0.88em;
        background: var(--code-bg);
        color: var(--code-text);
        padding: 0.15em 0.4em;
        border-radius: 4px;
    }

    .markdown-body pre {
        background: var(--code-bg);
        border: 1px solid var(--border);
        border-radius: 8px;
        padding: 16px;
        overflow-x: auto;
        margin-bottom: 1em;
        line-height: 1.45;
    }

    .markdown-body pre code {
        background: none;
        padding: 0;
        border-radius: 0;
        font-size: 13px;
        color: var(--code-text);
    }

    /* Syntax Highlighting */
    .hljs-keyword { color: #d73a49; font-weight: 600; }
    .hljs-string  { color: #032f62; }
    .hljs-comment { color: #6a737d; font-style: italic; }
    .hljs-number  { color: #005cc5; }

    @media (prefers-color-scheme: dark) {
        .hljs-keyword { color: #ff7b72; }
        .hljs-string  { color: #a5d6ff; }
        .hljs-comment { color: #8b949e; }
        .hljs-number  { color: #79c0ff; }
    }

    /* Blockquotes */

    .markdown-body blockquote {
        border-left: 4px solid var(--blockquote-border);
        color: var(--blockquote-text);
        padding: 0.5em 1em;
        margin: 0 0 1em 0;
    }

    .markdown-body blockquote p:last-child {
        margin-bottom: 0;
    }

    /* Tables */

    .markdown-body table {
        width: 100%;
        border-collapse: collapse;
        margin-bottom: 1em;
        font-size: 14px;
    }

    .markdown-body th,
    .markdown-body td {
        border: 1px solid var(--table-border);
        padding: 8px 12px;
        text-align: left;
    }

    .markdown-body th {
        background: var(--bg-secondary);
        font-weight: 600;
        font-size: 13px;
        text-transform: uppercase;
        letter-spacing: 0.02em;
    }

    .markdown-body tbody tr:nth-child(even) {
        background: var(--table-stripe);
    }

    /* Horizontal Rule */

    .markdown-body hr {
        border: none;
        border-top: 1px solid var(--hr);
        margin: 2em 0;
    }

    /* Images */

    .markdown-body img {
        max-width: 100%;
        height: auto;
        border-radius: 6px;
    }

    /* Definition-style list in frontmatter */
    .markdown-body dl {
        margin-bottom: 1em;
    }

    .markdown-body dt {
        font-weight: 600;
        margin-top: 0.5em;
    }

    .markdown-body dd {
        margin-left: 1em;
        margin-bottom: 0.25em;
    }

    /* Strikethrough */
    .markdown-body del {
        text-decoration: line-through;
        opacity: 0.65;
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
            'json': null,
            'yaml': null,
            'bash': /\\b(if|then|else|elif|fi|for|while|do|done|case|esac|function|return|local|export|source|echo|exit|test|cd|ls|grep|sed|awk|cat|mkdir|rm|cp|mv|chmod|chown|curl|wget|sudo|apt|brew|npm|git|docker)\\b/g,
            'sh': null,
            'html': null,
            'css': null,
            'sql': /\\b(SELECT|FROM|WHERE|INSERT|INTO|UPDATE|SET|DELETE|CREATE|DROP|ALTER|TABLE|INDEX|VIEW|JOIN|LEFT|RIGHT|INNER|OUTER|ON|AND|OR|NOT|IN|EXISTS|BETWEEN|LIKE|ORDER|BY|GROUP|HAVING|LIMIT|OFFSET|AS|NULL|IS|DISTINCT|UNION|ALL|COUNT|SUM|AVG|MIN|MAX|CASE|WHEN|THEN|ELSE|END|PRIMARY|KEY|FOREIGN|REFERENCES|CONSTRAINT|DEFAULT|VALUES)\\b/gi,
        };

        const stringRegex = /("(?:[^"\\\\]|\\\\.)*"|'(?:[^'\\\\]|\\\\.)*'|`(?:[^`\\\\]|\\\\.)*`)/g;
        const commentRegex = /(\\/\\/.*$|\\/\\*[\\s\\S]*?\\*\\/|#.*$)/gm;
        const numberRegex = /\\b(\\d+\\.?\\d*(?:e[+-]?\\d+)?|0x[0-9a-fA-F]+|0b[01]+|0o[0-7]+)\\b/g;

        document.querySelectorAll('pre code[class*="language-"]').forEach(function(block) {
            const langMatch = block.className.match(/language-(\\w+)/);
            if (!langMatch) return;
            const lang = langMatch[1].toLowerCase();

            let code = block.innerHTML;

            const stored = [];
            function store(match) {
                stored.push(match);
                return '%%STORED' + (stored.length - 1) + '%%';
            }

            code = code.replace(commentRegex, function(m) {
                return '<span class="hljs-comment">' + store(m).replace(/<span class="hljs-comment">|<\\/span>/g, '') + '</span>';
            });

            code = code.replace(stringRegex, '<span class="hljs-string">$1</span>');

            if (keywords[lang]) {
                code = code.replace(keywords[lang], '<span class="hljs-keyword">$1</span>');
            }

            code = code.replace(numberRegex, '<span class="hljs-number">$1</span>');

            block.innerHTML = code;
        });
    })();
    """

    // MARK: - Autolink Script

    static let autolinkScript = """
    (function() {
        // Auto-link bare URLs in text nodes that aren't already inside links or code
        const urlRegex = /(https?:\\/\\/[^\\s<>)\\]]+)/g;
        const article = document.querySelector('.markdown-body');
        if (!article) return;

        const walker = document.createTreeWalker(article, NodeFilter.SHOW_TEXT, {
            acceptNode: function(node) {
                const parent = node.parentElement;
                if (!parent) return NodeFilter.FILTER_REJECT;
                const tag = parent.tagName.toLowerCase();
                if (tag === 'a' || tag === 'code' || tag === 'pre' || tag === 'script') {
                    return NodeFilter.FILTER_REJECT;
                }
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
                if (match.index > lastIndex) {
                    frag.appendChild(document.createTextNode(text.slice(lastIndex, match.index)));
                }
                const a = document.createElement('a');
                a.href = match[1];
                a.textContent = match[1];
                frag.appendChild(a);
                lastIndex = urlRegex.lastIndex;
            }
            if (lastIndex < text.length) {
                frag.appendChild(document.createTextNode(text.slice(lastIndex)));
            }
            node.parentNode.replaceChild(frag, node);
        });
    })();
    """
}
