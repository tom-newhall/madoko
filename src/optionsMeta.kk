/*---------------------------------------------------------------------------
  Copyright 2013 Microsoft Corporation.
 
  This is free software; you can redistribute it and/or modify it under the
  terms of the Apache License, Version 2.0. A copy of the License can be
  found in the file "license.txt" at the root of this distribution.
---------------------------------------------------------------------------*/

// Options from metadata
module optionsMeta

import std/log
import std/path
import std/string
import common
import options
import optionsSandbox
import optionsMath

external import {
  js locs "./locales"
}

external normalizeLocale( lang : string ) : string {
  js inline "locs.getLocaleInfo(#1).langid"
}

public function fromMeta( opts : options, mdata : metadata ) : options {
  //opts = opts0(metadata = opts0.metadata + mdata)
  mdata.foldl(opts) fun(options : options, kv : (string,string)) {
    val (key,xvalue) = kv
    options.update( key, xvalue, mdata )
  }
}

function update( options : options, key : string, xvalue : string, mdata : metadata ) : options {  
  val lvalue = xvalue.toLower
  val value  = if (lvalue=="none" || lvalue=="clear" || lvalue=="false") then "" else xvalue
  val ivalue = value.parseInt.maybe(~1,id)
  val bvalue = (value!="" && value!="0") 

  //trace("from meta: " + key + "=" + value)
  if   (key=="title")  options(title=value)
  elif (key=="prelude") options(prelude=value)
  elif (key=="css")    options(css=if (value=="") then "" else options.css + ";" + value)
  elif (key=="html-meta")    options(htmlMeta=if (value=="") then "" else options.htmlMeta + ";" + value)
  elif (key=="script") options(scripts=if (value=="") then "" else options.scripts + ";" + value)
  elif (key=="script-") options(scriptsx=if (value=="") then "" else options.scriptsx + ";" + value)
  elif (key=="package") options(packages=if (value=="") then "" else options.packages + ";" + value)
  elif (key=="package-")  options(packagesx=if (value=="") then "" else options.packagesx + ";" + value)
  elif (key=="toc-depth" && ivalue >= 0) options(tocDepth = ivalue)
  elif ((key=="heading-depth" || key=="header-depth") && ivalue >= 0) options(headingDepth = ivalue)
  elif ((key=="heading-base" || key=="header-base" || key=="base-header-level") && ivalue >= 0) options(headingBase = ivalue)
  elif (key=="document-class" || key=="doc-class") options(docClass=value)
  //elif (key=="bib" || key=="bibliography" || key=="bib-data") options(bib=if (value=="") then "" else options.bib + ";" + value)
  elif (key=="bib" || key=="bibliography" || key=="bib-data") {
    if (value!="") log("files", value.changeExt(".bib"))
    options(bib=if (value=="") then "" else options.bib + ";" + value);
  }
  elif (key=="bib-style" || key=="biblio-style" || key=="bibliography-style") {
    if (value.extname!="" || value.dirname!="") { // we need to log here since we don't always 'read' the bst if the bibs are unchanged
      log("files", value.defaultExt(".bst"))
    }
    if (value.bool) then options(bibStyle=Bst(value,"")) else options
  }
  elif (key=="csl-style") { 
    val cslname = if (value.extname.isEmpty && value.dirname.isEmpty) 
                   then lvalue.replaceAll(" ","-") // normalize CSL style name
                   else value
    // we need to log here since we don't always 'read' the cls if the bibs are unchanged
    if (cslname.bool) {
      //log("files", cslname.defaultExt(".csl"))
      //log("files", "madoko.csl")
      //log("files", "locales-en-US.xml")
      options(bibStyle=Csl(cslname,"")) 
    }
    else options
  }
  elif (key=="locale") { options(locale=normalizeLocale(value)) }  
  elif (key=="html-header") options(htmlHeader=if(value=="") then "" else options.htmlHeader.appendNL(value))
  elif (key=="css-header") options(cssHeader=if(value=="") then "" else options.cssHeader.appendNL(value))
  elif (key=="html-footer") options(htmlFooter=if(value=="") then "" else options.htmlFooter.appendNL(value))
  elif (key=="js-header") options(jsHeader=if(value=="") then "" else options.jsHeader.appendNL(value))
  elif (key=="js-footer") options(jsFooter=if(value=="") then "" else options.jsFooter.appendNL(value))
  elif (key=="tex-header") options(texHeader =if(value=="") then "" else options.texHeader.appendNL(value))
  elif (key=="tex-header-") options(texHeaderx =if(value=="") then "" else options.texHeaderx.appendNL(value))
  elif (key=="tex-doc-header") options(texDocHeader =if(value=="") then "" else options.texDocHeader.appendNL(value))
  elif (key=="tex-doc-header-") options(texDocHeaderx =if(value=="") then "" else options.texDocHeaderx.appendNL(value))
  elif (key=="tex-footer") options(texFooter =if(value=="") then "" else options.texFooter.appendNL(value))
  elif (key=="tex-section-num") options(texSectionNum=(value!=""))
  elif (key=="fragment-start" || key=="extract-start") options(extractStart=xvalue)
  elif (key=="fragment-end" || key=="extract-end") options(extractEnd=xvalue)
  
  elif (key=="cite-style") {
    if (lvalue=="clear" || lvalue=="none") then options(citestyle = Nothing)
    elif (lvalue=="") then options
    else match(parseCiteStyle(lvalue)) {
      Nothing -> {
        warning("unrecognized citation style: " + lvalue)
        options
      }
      Just(cs) -> options(citestyle=Just(cs))
    }      
  }
  elif (key=="cite-all") options(citeAll=(value!="")) 
  elif (key=="embed" || key=="embed-limit") options(embedLimit=if (value=="") then 0 elif (value=="true") then 1024 else (ivalue*1024))
  elif (key=="section-depth") options(sectionMax=ivalue)
  elif (key=="section-base") options(sectionBase=ivalue)
  elif (key=="highlight" || key=="colorize") options(highlight=if (value=="") then False else True)
  elif (key=="highlight-language" || key=="colorizer") options(hilitelang=if (value=="") then "" else options.hilitelang + ";" + value)
  elif (key=="rebuild") options(rebuild=(value != ""))
  elif (key=="star-bold") options(starBold=(value!=""))
  elif (key=="line-no") options(lineNo=ivalue)
  elif (key=="line-no-web") options(lineNoWeb = (lvalue=="true"))
  elif (key=="pretty-align") options(prettyAlign=ivalue)
  elif (key=="logo") options(logo=(lvalue=="true"))
  elif (key=="refer") { log("filesRefer",value); options }
  elif (key=="copy-styles") options(copyStyles=(value!=""))
  elif (key.startsWith("math")) {
    options.updateMath( key, lvalue, value, ivalue, bvalue )
  }
  else {
    options.updateSandbox( key, lvalue, value, ivalue )
  }
}


function appendNL(s : string, t : string ) : string {
  if (s == "" || s.endsWith("\n")) then s + t else s + "\n" + t
}


function appendValue( xs : list<string>, x : string, sep : string = "&br;" ) : list<string> {
  match(xs.reverse) {
    Nil -> [x]
    Cons(y,yy) -> if (y=="") then Cons(x,yy).reverse else Cons(y + sep + x,yy).reverse
  }
}