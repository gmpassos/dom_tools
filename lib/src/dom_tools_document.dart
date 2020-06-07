
import 'dart:html';

import 'package:highlight/highlight.dart' ;
import 'package:markdown/markdown.dart' as mk ;
import 'package:swiss_knife/swiss_knife.dart';

import 'dom_tools_base.dart';
import 'dom_tools_css.dart';


const CODE_THEME_0 = {
  'comment': TextStyle(color: StyleColor(0xffd4d0ab)),
  'quote': TextStyle(color: StyleColor(0xffd4d0ab)),
  'variable': TextStyle(color: StyleColor(0xffffa07a)),
  'template-variable': TextStyle(color: StyleColor(0xffffa07a)),
  'tag': TextStyle(color: StyleColor(0xffffa07a)),
  'name': TextStyle(color: StyleColor(0xffffa07a)),
  'selector-id': TextStyle(color: StyleColor(0xffffa07a)),
  'selector-class': TextStyle(color: StyleColor(0xffffa07a)),
  'regexp': TextStyle(color: StyleColor(0xffffa07a)),
  'deletion': TextStyle(color: StyleColor(0xffffa07a)),
  'number': TextStyle(color: StyleColor(0xfff5ab35)),
  'built_in': TextStyle(color: StyleColor(0xfff5ab35)),
  'builtin-name': TextStyle(color: StyleColor(0xfff5ab35)),
  'literal': TextStyle(color: StyleColor(0xfff5ab35)),
  'type': TextStyle(color: StyleColor(0xfff5ab35)),
  'params': TextStyle(color: StyleColor(0xfff5ab35)),
  'meta': TextStyle(color: StyleColor(0xfff5ab35)),
  'link': TextStyle(color: StyleColor(0xfff5ab35)),
  'attribute': TextStyle(color: StyleColor(0xffffd700)),
  'string': TextStyle(color: StyleColor(0xffabe338)),
  'symbol': TextStyle(color: StyleColor(0xffabe338)),
  'bullet': TextStyle(color: StyleColor(0xffabe338)),
  'addition': TextStyle(color: StyleColor(0xffabe338)),
  'title': TextStyle(color: StyleColor(0xff00e0e0)),
  'section': TextStyle(color: StyleColor(0xff00e0e0)),
  'keyword': TextStyle(color: StyleColor(0xffdcc6e0)),
  'selector-tag': TextStyle(color: StyleColor(0xffdcc6e0)),
  'root':
  TextStyle(backgroundColor: StyleColor(0xff2b2b2b), color: StyleColor(0xfff8f8f2)),
  'emphasis': TextStyle(fontStyle: FontStyle.italic),
  'strong': TextStyle(fontWeight: FontWeight.bold),
};


const CODE_THEME_1 = {
  'root':
  TextStyle(color: StyleColor(0xff000000), backgroundColor: StyleColor(0xffffffff)),
  'subst': TextStyle(fontWeight: FontWeight.normal, color: StyleColor(0xff000000)),
  'title': TextStyle(fontWeight: FontWeight.normal, color: StyleColor(0xff000000)),
  'comment': TextStyle(color: StyleColor(0xff808080), fontStyle: FontStyle.italic),
  'quote': TextStyle(color: StyleColor(0xff808080), fontStyle: FontStyle.italic),
  'meta': TextStyle(color: StyleColor(0xff808000)),
  'tag': TextStyle(backgroundColor: StyleColor(0xffefefef)),
  'section': TextStyle(fontWeight: FontWeight.bold, color: StyleColor(0xff000080)),
  'name': TextStyle(fontWeight: FontWeight.bold, color: StyleColor(0xff000080)),
  'literal': TextStyle(fontWeight: FontWeight.bold, color: StyleColor(0xff000080)),
  'keyword': TextStyle(fontWeight: FontWeight.bold, color: StyleColor(0xff000080)),
  'selector-tag':
  TextStyle(fontWeight: FontWeight.bold, color: StyleColor(0xff000080)),
  'type': TextStyle(fontWeight: FontWeight.bold, color: StyleColor(0xff000080)),
  'selector-id':
  TextStyle(fontWeight: FontWeight.bold, color: StyleColor(0xff000080)),
  'selector-class':
  TextStyle(fontWeight: FontWeight.bold, color: StyleColor(0xff000080)),
  'attribute': TextStyle(fontWeight: FontWeight.bold, color: StyleColor(0xff0000ff)),
  'number': TextStyle(fontWeight: FontWeight.normal, color: StyleColor(0xff0000ff)),
  'regexp': TextStyle(fontWeight: FontWeight.normal, color: StyleColor(0xff0000ff)),
  'link': TextStyle(fontWeight: FontWeight.normal, color: StyleColor(0xff0000ff)),
  'string': TextStyle(color: StyleColor(0xff008000), fontWeight: FontWeight.bold),
  'symbol': TextStyle(
      color: StyleColor(0xff000000),
      backgroundColor: StyleColor(0xffd0eded),
      fontStyle: FontStyle.italic),
  'bullet': TextStyle(
      color: StyleColor(0xff000000),
      backgroundColor: StyleColor(0xffd0eded),
      fontStyle: FontStyle.italic),
  'formula': TextStyle(
      color: StyleColor(0xff000000),
      backgroundColor: StyleColor(0xffd0eded),
      fontStyle: FontStyle.italic),
  'variable': TextStyle(color: StyleColor(0xff660e7a)),
  'template-variable': TextStyle(color: StyleColor(0xff660e7a)),
  'addition': TextStyle(backgroundColor: StyleColor(0xffbaeeba)),
  'deletion': TextStyle(backgroundColor: StyleColor(0xffffc8bd)),
  'emphasis': TextStyle(fontStyle: FontStyle.italic),
  'strong': TextStyle(fontWeight: FontWeight.bold),
};

const CODE_THEME_2 = {
  'comment': TextStyle(color: StyleColor(0xff7e7887)),
  'quote': TextStyle(color: StyleColor(0xff7e7887)),
  'variable': TextStyle(color: StyleColor(0xffbe4678)),
  'template-variable': TextStyle(color: StyleColor(0xffbe4678)),
  'attribute': TextStyle(color: StyleColor(0xffbe4678)),
  'regexp': TextStyle(color: StyleColor(0xffbe4678)),
  'link': TextStyle(color: StyleColor(0xffbe4678)),
  'tag': TextStyle(color: StyleColor(0xffbe4678)),
  'name': TextStyle(color: StyleColor(0xffbe4678)),
  'selector-id': TextStyle(color: StyleColor(0xffbe4678)),
  'selector-class': TextStyle(color: StyleColor(0xffbe4678)),
  'number': TextStyle(color: StyleColor(0xffaa573c)),
  'meta': TextStyle(color: StyleColor(0xffaa573c)),
  'built_in': TextStyle(color: StyleColor(0xffaa573c)),
  'builtin-name': TextStyle(color: StyleColor(0xffaa573c)),
  'literal': TextStyle(color: StyleColor(0xffaa573c)),
  'type': TextStyle(color: StyleColor(0xffaa573c)),
  'params': TextStyle(color: StyleColor(0xffaa573c)),
  'string': TextStyle(color: StyleColor(0xff2a9292)),
  'symbol': TextStyle(color: StyleColor(0xff2a9292)),
  'bullet': TextStyle(color: StyleColor(0xff2a9292)),
  'title': TextStyle(color: StyleColor(0xff576ddb)),
  'section': TextStyle(color: StyleColor(0xff576ddb)),
  'keyword': TextStyle(color: StyleColor(0xff955ae7)),
  'selector-tag': TextStyle(color: StyleColor(0xff955ae7)),
  'deletion':
  TextStyle(color: StyleColor(0xff19171c), backgroundColor: StyleColor(0xffbe4678)),
  'addition':
  TextStyle(color: StyleColor(0xff19171c), backgroundColor: StyleColor(0xff2a9292)),
  'root':
  TextStyle(backgroundColor: StyleColor(0xff19171c), color: StyleColor(0xff8b8792)),
  'emphasis': TextStyle(fontStyle: FontStyle.italic),
  'strong': TextStyle(fontWeight: FontWeight.bold),
};

final CSSThemeSet CODE_THEME = CSSThemeSet('hljs-', [CODE_THEME_0, CODE_THEME_1, CODE_THEME_2], 2) ;

/// Converts [code] to a highlighted HTML version.
///
/// [code] The code to parse and highlight.
/// [language] The language of the code. If null will try to detect automatically.
/// [normalize] If [true] normalizes ident, skipping common/global ident from code.
String codeToHighlightHtml( String code, { String language, bool normalize = true } ) {
  if ( normalize != null && normalize ) code = normalizeIdent(code) ;

  var result ;
  if (language == null || language.isEmpty) {
    result = highlight.parse(code, autoDetection: true);
  }
  else {
    result = highlight.parse(code, language: language);
  }

  CODE_THEME.ensureThemeLoaded() ;

  return result != null ? result.toHtml() : null ;
}

/// Normalizes a ident, removing the common/global ident of the code.
///
/// Useful to remove ident caused due declaration inside a multiline String
/// with it's own indentation.
String normalizeIdent(String text) {
  if (text == null || text.isEmpty) return text ;

  var lines = text.split( RegExp(r'[\r\n]') ) ;

  if (lines.length <= 2) return text ;

  // ignore: omit_local_variable_types
  Map<String,int> identCount = {} ;

  for (var line in lines) {
    var ident = line.split( RegExp(r'\S') )[0] ;
    var count = identCount[ident] ?? 0 ;
    identCount[ident] = count+1 ;
  }

  if (identCount.isEmpty) return text ;

  var identList = List.from( identCount.keys )..sort( (a,b) => identCount[b].compareTo(identCount[a]) ) ;

  String mainIdent = identList[0] ;

  if (mainIdent.isEmpty) return text ;

  for (var i = 0 ; i < lines.length ; i++) {
    var line = lines[i] ;
    if (line.startsWith(mainIdent)) {
      var line2 = line.substring( mainIdent.length );
      lines[i] = line2 ;
    }
  }

  var textNorm = lines.join('\n') ;

  return textNorm ;
}

/// Converts a [markdown] document into a HTML in a div node.
///
/// [markdown] The markdown document.
/// [normalize] If [true] normalizes ident.
DivElement markdownToDiv( String markdown, { bool normalize = true , Iterable<mk.BlockSyntax> blockSyntaxes, Iterable<mk.InlineSyntax> inlineSyntaxes, mk.ExtensionSet extensionSet, mk.Resolver linkResolver, mk.Resolver imageLinkResolver, bool inlineOnly = false } ) {
  if ( markdown == null || markdown.isEmpty ) return createDivInline() ;
  var html = markdownToHtml(markdown, blockSyntaxes: blockSyntaxes, inlineSyntaxes: inlineSyntaxes, extensionSet: extensionSet, linkResolver: linkResolver, imageLinkResolver: imageLinkResolver, inlineOnly: inlineOnly);
  return createDivInline(html) ;
}

/// Converts a [markdown] document into a HTML.
///
/// [markdown] The markdown document.
/// [normalize] If [true] normalizes ident.
String markdownToHtml( String markdown, { bool normalize = true , Iterable<mk.BlockSyntax> blockSyntaxes, Iterable<mk.InlineSyntax> inlineSyntaxes, mk.ExtensionSet extensionSet, mk.Resolver linkResolver, mk.Resolver imageLinkResolver, bool inlineOnly = false } ) {
  if ( markdown == null || markdown.isEmpty ) return '';
  if ( normalize != null && normalize ) markdown = normalizeIdent(markdown) ;
  var markdownHtml = mk.markdownToHtml(markdown, blockSyntaxes: blockSyntaxes, inlineSyntaxes: inlineSyntaxes, extensionSet: extensionSet, linkResolver: linkResolver, imageLinkResolver: imageLinkResolver, inlineOnly: inlineOnly);

  // allow attributes for url. For example:
  // [GitHub](https://github.com/){:target="_blank"}
  markdownHtml = regExpReplaceAll(RegExp(r'(<a.*?)(>.*?</a>){:(.*?)}', multiLine: false, caseSensitive: false), markdownHtml, r'$1 $3$2') ;

  return markdownHtml ;
}

