/* attributedStringConsumer.m

   Copyright (C) 1999 Free Software Foundation, Inc.

   Author:  Stefan B�hringer (stefan.boehringer@uni-bochum.de)
   Date: Dec 1999

   This file is part of the GNUstep GUI Library.

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Library General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.

   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.	 See the GNU
   Library General Public License for more details.

   You should have received a copy of the GNU Library General Public
   License along with this library; see the file COPYING.LIB.
   If not, write to the Free Software Foundation,
   59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
*/

#import	<Foundation/Foundation.h>
#import	<AppKit/AppKit.h>
#import "Parsers/rtfConsumer.h"

/*  we have to satisfy the scanner with a stream reading function */
typedef struct {
  NSString	*string;
  int		position;
  int		length;
} StringContext;

static void	
initStringContext(StringContext *ctxt, NSString *string)
{
  ctxt->string = string;
  ctxt->position = 0;
  ctxt->length = [string length];
}

static int	
readNSString(StringContext *ctxt)
{
  return (ctxt->position < ctxt->length )
    ? [ctxt->string characterAtIndex:ctxt->position++]: EOF;
}

/*
  we must implement from the rtfConsumerSkeleton.h file (Supporting files)
  this includes the yacc error handling and output
*/
#define	CTXT	((NSMutableDictionary *)ctxt)
#define	FONTS	[CTXT objectForKey:GSRTFfontDictName]
#define	RESULT	[CTXT objectForKey:GSRTFresultName]

#define	GSRTFfontDictName			@"fonts"
#define	GSRTFcurrentTextPosition	@"textPosition"
#define	GSRTFresultName				@"result"
#define	GSRTFboldRange				@"boldOn"
#define	GSRTFitalicRange			@"italicOn"
#define	GSRTFunderlineRange			@"underlineOn"
#define	GSRTFcurrentFont			@"currentFont"
#define	GSRTFdocumentAttributes		@"documentAttributes"

static NSRange MakeRangeFromAbs(int a1,int a2)
{
  if(a1< a2)	return NSMakeRange(a1,a2-a1);	
  else		return NSMakeRange(a2,a1-a2);
}

/*	handle errors (this is the yacc error mech)	*/
void	GSRTFerror(const char *msg)
{
  [NSException raise:NSInvalidArgumentException 
	       format:@"Syntax error in RTF:%s", msg];
}

void	GSRTFgenericRTFcommand(void *ctxt, RTFcmd cmd)
{
  fprintf(stderr, "encountered rtf cmd:%s", cmd.name);
  if (cmd.isEmpty) fprintf(stderr, " argument is empty\n");
  else		   fprintf(stderr, " argument is %d\n", cmd.parameter);
}

//Start: we're doing some initialization
void	GSRTFstart(void *ctxt)
{
  [CTXT setObject:[NSNumber numberWithInt:0] forKey: GSRTFcurrentTextPosition];
  [CTXT setObject:[NSFont userFontOfSize:12] forKey: GSRTFcurrentFont];
  [CTXT setObject:[NSMutableDictionary dictionary] forKey: GSRTFfontDictName];
  [RESULT beginEditing];
}

// Finished to parse one piece of RTF.
void	GSRTFstop(void *ctxt)
{
  //<!> close all open bolds et al.
  [RESULT beginEditing];
}

void	GSRTFopenBlock(void *ctxt)
{
}

void	GSRTFcloseBlock(void *ctxt)
{
}

void	GSRTFmangleText(void *ctxt, const char *text)
{
  int  oldPosition=[[CTXT objectForKey: GSRTFcurrentTextPosition] intValue],
    textlen=strlen(text), 
    newPosition=oldPosition + textlen;
  NSRange		insertionRange=NSMakeRange(oldPosition,0);
  NSDictionary *attributes=[NSDictionary dictionaryWithObjectsAndKeys:
					 [CTXT objectForKey:GSRTFcurrentFont],
					 NSFontAttributeName,nil];
  
  [CTXT setObject:[NSNumber numberWithInt:newPosition] 
	forKey: GSRTFcurrentTextPosition];
  
  [RESULT replaceCharactersInRange:insertionRange 
	  withString:[NSString stringWithCString:text]];
  [RESULT setAttributes:attributes range:NSMakeRange(oldPosition,textlen)];
}

void	GSRTFregisterFont(void *ctxt, const char *fontName, 
			  RTFfontFamily family, int fontNumber)
{
  NSMutableDictionary	*fonts = FONTS;
  NSString		*fontNameString;
  NSNumber		*fontId = [NSNumber numberWithInt:fontNumber];

  if (!fontName || !*fontName || !fontId)	// <?> fontId ist nie null
    {	
      [NSException raise:NSInvalidArgumentException 
		   format:@"Error in RTF (font omitted?), position:%d",
		   [[CTXT objectForKey:GSRTFcurrentTextPosition] intValue]];
    }
  //	exclude trailing ';' from fontName
  fontNameString = [NSString stringWithCString:fontName length:strlen(fontName)-1];
  [fonts setObject:fontNameString forKey:fontId];
}

void	GSRTFchangeFontTo(void *ctxt, int fontNumber)
{
  NSDictionary	*fonts = FONTS;
  NSNumber	*fontId = [NSNumber numberWithInt:fontNumber];
  NSFont	*font=[NSFont fontWithName:[fonts objectForKey:fontId] 
			      size:[[CTXT objectForKey:GSRTFcurrentFont] pointSize]];

  if (!font)	/* we're about to set an unknown font */
    {
      [NSException raise:NSInvalidArgumentException 
		   format:@"Error in RTF (referring to undefined font \\f%d), position:%d",
		   fontNumber,
		   [[CTXT objectForKey:GSRTFcurrentTextPosition] intValue]];
    } else {
      font=[[NSFontManager sharedFontManager] 
	     convertFont:[CTXT objectForKey:GSRTFcurrentFont] 
	     toFamily:[font familyName]];
      [CTXT setObject:font forKey: GSRTFcurrentFont];
    }
}

//	<N> fontSize is in halfpoints according to spec
#define	fs2points(a)	((a)/2.0)
void	GSRTFchangeFontSizeTo(void *ctxt, int fontSize)
{
  [CTXT setObject:[[NSFontManager sharedFontManager] 
		    convertFont:[CTXT objectForKey:GSRTFcurrentFont] 
		    toSize:fs2points(fontSize)]
	forKey:GSRTFcurrentFont];
}


static NSRange rangeForContextAndAttribute(void *ctxt, NSString *attrib)
{
  NSString *attribStartString=[CTXT objectForKey:GSRTFboldRange];
  
  if(!attribStartString)
    {
      NSLog(@"RTF anomality (attribute:%@ off statement unpaired with on statement), position:%d",
	    attrib, [[CTXT objectForKey:GSRTFcurrentTextPosition] intValue]);
      return NSMakeRange(0, 0);
    }
  return MakeRangeFromAbs([attribStartString intValue],
			  [[CTXT objectForKey:GSRTFcurrentTextPosition] intValue]);
}

void	GSRTFhandleItalicAttribute(void *ctxt, BOOL state)
{
  if(!state)	// this indicates a bold off
    {	
      [RESULT addAttribute:NSFontAttributeName
	      value:[[NSFontManager sharedFontManager] 
		      convertFont:[CTXT objectForKey:GSRTFcurrentFont] 
		      toHaveTrait:NSItalicFontMask]
	      range:rangeForContextAndAttribute(ctxt,GSRTFboldRange)];
    } else {	
      [CTXT setObject:[CTXT objectForKey:GSRTFcurrentTextPosition] forKey:GSRTFitalicRange];
    }
}

void	GSRTFhandleBoldAttribute(void *ctxt, BOOL state)
{
  if(!state)	// this indicates a bold off
    {	
      [RESULT addAttribute:NSFontAttributeName
	      value:[[NSFontManager sharedFontManager] 
		      convertFont:[CTXT objectForKey:GSRTFcurrentFont] 
		      toHaveTrait:NSBoldFontMask]
	      range:rangeForContextAndAttribute(ctxt,GSRTFboldRange)];
    } else {	
      [CTXT setObject:[CTXT objectForKey:GSRTFcurrentTextPosition] 
	    forKey:GSRTFboldRange];
      }
}

void	GSRTFhandleDocumentAttribute(void *ctxt, int attrib)
{
}

NSMutableAttributedString	*attributedStringFromRTF(NSString *rtfString)
{
  RTFscannerCtxt	scanner;
  StringContext		stringCtxt;
  NSMutableDictionary	*myDict = [NSMutableDictionary dictionary];
  NSMutableAttributedString  *result=[[NSMutableAttributedString alloc] init];
  
  [myDict setObject:result forKey: GSRTFresultName];
  initStringContext(&stringCtxt, rtfString);
  lexInitContext(&scanner, &stringCtxt, (int (*)(void*))readNSString);
  GSRTFparse(myDict, &scanner);
  
  return [result autorelease];
}

@implementation NSAttributedString (RTFParser)

- (id) initWithRTF: (NSData*)data
  documentAttributes: (NSDictionary**)dict
{
  RTFscannerCtxt       scanner;
  StringContext	       stringCtxt;
  NSMutableDictionary  *myDict = [NSMutableDictionary dictionary];
  NSString	       *parseString = [NSString stringWithCString:[data bytes] 
						length:[data length]];
  NSMutableAttributedString  *result =
    [[[NSMutableAttributedString alloc] init] autorelease];
  
  [myDict setObject:result forKey: GSRTFresultName];
  initStringContext(&stringCtxt, parseString);
  lexInitContext(&scanner, &stringCtxt, (int (*)(void*))readNSString);
  GSRTFparse(myDict, &scanner);
  
  if (dict && [myDict objectForKey:GSRTFdocumentAttributes])
    (*dict)=[myDict objectForKey:GSRTFdocumentAttributes];	// document 
  [self autorelease];
  return [[[self class] alloc] initWithAttributedString:result];
}

@end
