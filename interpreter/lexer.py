
import re

from pygments.lexer import RegexLexer, include, bygroups, default, words
from pygments.token import Text, Comment, Operator, Keyword, Name, String, \
    Number, Punctuation, Error


class Lexer(RegexLexer):
    """
    For the Standard ML language.

    .. versionadded:: 1.5
    """

    name = 'Standard ML'
    aliases = ['sml']
    filenames = ['*.sml', '*.sig', '*.fun']
    mimetypes = ['text/x-standardml', 'application/x-standardml']

    alphanumid_reserved = {
        # Core
        'abstype', 'and', 'andalso', 'as', 'case', 'datatype', 'do', 'else',
        'end', 'exception', 'fn', 'fun', 'handle', 'if', 'in', 'infix',
        'infixr', 'let', 'local', 'nonfix', 'of', 'op', 'open', 'orelse',
        'raise', 'rec', 'then', 'type', 'val', 'with', 'withtype', 'while',
        # Modules
        'eqtype', 'functor', 'include', 'sharing', 'sig', 'signature',
        'struct', 'structure', 'where',
    }

    symbolicid_reserved = {
        # Core
        ':', r'\|', '=', '=>', '->', '#',
        # Modules
        ':>',
    }

    nonid_reserved = {'(', ')', '[', ']', '{', '}', ',', ';', '...', '_'}

    alphanumid_re = r"[a-zA-Z][\w']*"
    symbolicid_re = r"[!%&$#+\-/:<=>?@\\~`^|*]+"

    # A character constant is a sequence of the form #s, where s is a string
    # constant denoting a string of size one character. This setup just parses
    # the entire string as either a String.Double or a String.Char (depending
    # on the argument), even if the String.Char is an erroneous
    # multiple-character string.
    def stringy(whatkind):
        return [
            (r'[^"\\]', whatkind),
            (r'\\[\\"abtnvfr]', String.Escape),
            # Control-character notation is used for codes < 32,
            # where \^@ == \000
            (r'\\\^[\x40-\x5e]', String.Escape),
            # Docs say 'decimal digits'
            (r'\\[0-9]{3}', String.Escape),
            (r'\\u[0-9a-fA-F]{4}', String.Escape),
            (r'\\\s+\\', String.Interpol),
            (r'"', whatkind, '#pop'),
        ]

    # Callbacks for distinguishing tokens and reserved words
    def long_id_callback(self, match):
        if match.group(1) in self.alphanumid_reserved:
            token = Error
        else:
            token = Name.Namespace
        yield match.start(1), token, match.group(1)
        yield match.start(2), Punctuation, match.group(2)

    def end_id_callback(self, match):
        if match.group(1) in self.alphanumid_reserved:
            token = Error
        elif match.group(1) in self.symbolicid_reserved:
            token = Error
        else:
            token = Name
        yield match.start(1), token, match.group(1)

    def id_callback(self, match):
        str = match.group(1)
        if str in self.alphanumid_reserved:
            token = Keyword.Reserved
        elif str in self.symbolicid_reserved:
            token = Punctuation
        else:
            token = Name
        yield match.start(1), token, str

    tokens = {
        # Whitespace and comments are (almost) everywhere
        'whitespace': [
            (r'\s+', Text),
            (r'\(\*', Comment.Multiline, 'comment'),
        ],

        'delimiters': [
            # This lexer treats these delimiters specially:
            # Delimiters define scopes, and the scope is how the meaning of
            # the `|' is resolved - is it a case/handle expression, or function
            # definition by cases? (This is not how the Definition works, but
            # it's how MLton behaves, see http://mlton.org/SMLNJDeviations)
            (r'\(|\[|\{', Punctuation, 'main'),
            (r'\)|\]|\}', Punctuation, '#pop'),
            (r'\b(let|if|local)\b(?!\')', Keyword.Reserved, ('main', 'main')),
            (r'\b(struct|sig|while)\b(?!\')', Keyword.Reserved, 'main'),
            (r'\b(do|else|end|in|then)\b(?!\')', Keyword.Reserved, '#pop'),
        ],

        'core': [
            # Punctuation that doesn't overlap symbolic identifiers
            (r'(%s)' % '|'.join(re.escape(z) for z in nonid_reserved),
             Punctuation),

            # Special constants: strings, floats, numbers in decimal and hex
            (r'#"', String.Char, 'char'),
            (r'"', String.Double, 'string'),
            (r'~?0x[0-9a-fA-F]+', Number.Hex),
            (r'0wx[0-9a-fA-F]+', Number.Hex),
            (r'0w\d+', Number.Integer),
            (r'~?\d+\.\d+[eE]~?\d+', Number.Float),
            (r'~?\d+\.\d+', Number.Float),
            (r'~?\d+[eE]~?\d+', Number.Float),
            (r'~?\d+', Number.Integer),

            # Labels
            (r'#\s*[1-9][0-9]*', Name.Label),
            (r'#\s*(%s)' % alphanumid_re, Name.Label),
            (r'#\s+(%s)' % symbolicid_re, Name.Label),
            # Some reserved words trigger a special, local lexer state change
            (r'\b(datatype|abstype)\b(?!\')', Keyword.Reserved, 'dname'),
            (r'\b(exception)\b(?!\')', Keyword.Reserved, 'ename'),
            (r'\b(functor|include|open|signature|structure)\b(?!\')',
             Keyword.Reserved, 'sname'),
            (r'\b(type|eqtype)\b(?!\')', Keyword.Reserved, 'tname'),

            # Regular identifiers, long and otherwise
            (r'\'[\w\']*', Name.Decorator),
            (r'(%s)(\.)' % alphanumid_re, long_id_callback, "dotted"),
            (r'(%s)' % alphanumid_re, id_callback),
            (r'(%s)' % symbolicid_re, id_callback),
        ],
        'dotted': [
            (r'(%s)(\.)' % alphanumid_re, long_id_callback),
            (r'(%s)' % alphanumid_re, end_id_callback, "#pop"),
            (r'(%s)' % symbolicid_re, end_id_callback, "#pop"),
            (r'\s+', Error),
            (r'\S+', Error),
        ],


        # Main parser (prevents errors in files that have scoping errors)
        'root': [
            default('main')
        ],

        # In this scope, I expect '|' to not be followed by a function name,
        # and I expect 'and' to be followed by a binding site
        'main': [
            include('whitespace'),
            (r'#.*$', Comment.Single),
            
            # Special behavior of val/and/fun
            (r'\b(val|and)\b(?!\')', Keyword.Reserved, 'vname'),
            (r'\b(fun)\b(?!\')', Keyword.Reserved,
             ('#pop', 'main-fun', 'fname')),

            include('delimiters'),
            include('core'),
            (r'\S+', Error),
        ],

        # In this scope, I expect '|' and 'and' to be followed by a function
        'main-fun': [
            include('whitespace'),

            (r'\s', Text),
            (r'\(\*', Comment.Multiline, 'comment'),

            # Special behavior of val/and/fun
            (r'\b(fun|and)\b(?!\')', Keyword.Reserved, 'fname'),
            (r'\b(val)\b(?!\')', Keyword.Reserved,
             ('#pop', 'main', 'vname')),

            # Special behavior of '|' and '|'-manipulating keywords
            (r'\|', Punctuation, 'fname'),
            (r'\b(case|handle)\b(?!\')', Keyword.Reserved,
             ('#pop', 'main')),

            include('delimiters'),
            include('core'),
            (r'\S+', Error),
        ],

        # Character and string parsers
        'char': stringy(String.Char),
        'string': stringy(String.Double),

        'breakout': [
            (r'(?=\b(%s)\b(?!\'))' % '|'.join(alphanumid_reserved), Text, '#pop'),
        ],

        # Dealing with what comes after module system keywords
        'sname': [
            include('whitespace'),
            include('breakout'),

            (r'(%s)' % alphanumid_re, Name.Namespace),
            default('#pop'),
        ],

        # Dealing with what comes after the 'fun' (or 'and' or '|') keyword
        'fname': [
            include('whitespace'),
            (r'\'[\w\']*', Name.Decorator),
            (r'\(', Punctuation, 'tyvarseq'),

            (r'(%s)' % alphanumid_re, Name.Function, '#pop'),
            (r'(%s)' % symbolicid_re, Name.Function, '#pop'),

            # Ignore interesting function declarations like "fun (x + y) = ..."
            default('#pop'),
        ],

        # Dealing with what comes after the 'val' (or 'and') keyword
        'vname': [
            include('whitespace'),
            (r'\'[\w\']*', Name.Decorator),
            (r'\(', Punctuation, 'tyvarseq'),

            (r'(%s)(\s*)(=(?!%s))' % (alphanumid_re, symbolicid_re),
             bygroups(Name.Variable, Text, Punctuation), '#pop'),
            (r'(%s)(\s*)(=(?!%s))' % (symbolicid_re, symbolicid_re),
             bygroups(Name.Variable, Text, Punctuation), '#pop'),
            (r'(%s)' % alphanumid_re, Name.Variable, '#pop'),
            (r'(%s)' % symbolicid_re, Name.Variable, '#pop'),

            # Ignore interesting patterns like 'val (x, y)'
            default('#pop'),
        ],

        # Dealing with what comes after the 'type' (or 'and') keyword
        'tname': [
            include('whitespace'),
            include('breakout'),

            (r'\'[\w\']*', Name.Decorator),
            (r'\(', Punctuation, 'tyvarseq'),
            (r'=(?!%s)' % symbolicid_re, Punctuation, ('#pop', 'typbind')),

            (r'(%s)' % alphanumid_re, Keyword.Type),
            (r'(%s)' % symbolicid_re, Keyword.Type),
            (r'\S+', Error, '#pop'),
        ],

        # A type binding includes most identifiers
        'typbind': [
            include('whitespace'),

            (r'\b(and)\b(?!\')', Keyword.Reserved, ('#pop', 'tname')),

            include('breakout'),
            include('core'),
            (r'\S+', Error, '#pop'),
        ],

        # Dealing with what comes after the 'datatype' (or 'and') keyword
        'dname': [
            include('whitespace'),
            include('breakout'),

            (r'\'[\w\']*', Name.Decorator),
            (r'\(', Punctuation, 'tyvarseq'),
            (r'(=)(\s*)(datatype)',
             bygroups(Punctuation, Text, Keyword.Reserved), '#pop'),
            (r'=(?!%s)' % symbolicid_re, Punctuation,
             ('#pop', 'datbind', 'datcon')),

            (r'(%s)' % alphanumid_re, Keyword.Type),
            (r'(%s)' % symbolicid_re, Keyword.Type),
            (r'\S+', Error, '#pop'),
        ],

        # common case - A | B | C of int
        'datbind': [
            include('whitespace'),

            (r'\b(and)\b(?!\')', Keyword.Reserved, ('#pop', 'dname')),
            (r'\b(withtype)\b(?!\')', Keyword.Reserved, ('#pop', 'tname')),
            (r'\b(of)\b(?!\')', Keyword.Reserved),

            (r'(\|)(\s*)(%s)' % alphanumid_re,
             bygroups(Punctuation, Text, Name.Class)),
            (r'(\|)(\s+)(%s)' % symbolicid_re,
             bygroups(Punctuation, Text, Name.Class)),

            include('breakout'),
            include('core'),
            (r'\S+', Error),
        ],

        # Dealing with what comes after an exception
        'ename': [
            include('whitespace'),

            (r'(and\b)(\s+)(%s)' % alphanumid_re,
             bygroups(Keyword.Reserved, Text, Name.Class)),
            (r'(and\b)(\s*)(%s)' % symbolicid_re,
             bygroups(Keyword.Reserved, Text, Name.Class)),
            (r'\b(of)\b(?!\')', Keyword.Reserved),
            (r'(%s)|(%s)' % (alphanumid_re, symbolicid_re), Name.Class),

            default('#pop'),
        ],

        'datcon': [
            include('whitespace'),
            (r'(%s)' % alphanumid_re, Name.Class, '#pop'),
            (r'(%s)' % symbolicid_re, Name.Class, '#pop'),
            (r'\S+', Error, '#pop'),
        ],

        # Series of type variables
        'tyvarseq': [
            (r'\s', Text),
            (r'\(\*', Comment.Multiline, 'comment'),

            (r'\'[\w\']*', Name.Decorator),
            (alphanumid_re, Name),
            (r',', Punctuation),
            (r'\)', Punctuation, '#pop'),
            (symbolicid_re, Name),
        ],

        'comment': [
            (r'[^(*)]', Comment.Multiline),
            (r'\(\*', Comment.Multiline, '#push'),
            (r'\*\)', Comment.Multiline, '#pop'),
            (r'[(*)]', Comment.Multiline),
        ],
    }
