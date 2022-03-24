//
//  AttributedStringBuilderUtils.m
//  ElementX
//
//  Created by Stefan Ceriu on 23/03/2022.
//  Copyright © 2022 Element. All rights reserved.
//

#import "AttributedStringBuilderUtils.h"
@import DTCoreText;

// Temporary background color used to identify blockquote blocks with DTCoreText.
#define kMXKToolsBlockquoteMarkColor [UIColor magentaColor]

// Attribute in an NSAttributeString that marks a blockquote block that was in the original HTML string.
NSString *const kMXKToolsBlockquoteMarkAttribute = @"kMXKToolsBlockquoteMarkAttribute";

@implementation AttributedStringBuilderUtils

+ (NSAttributedString *)removeDTCoreTextArtifacts:(NSAttributedString *)attributedString
{
    NSMutableAttributedString *mutableAttributedString = [[NSMutableAttributedString alloc] initWithAttributedString:attributedString];
    
    // DTCoreText adds a newline at the end of plain text ( https://github.com/Cocoanetics/DTCoreText/issues/779 )
    // or after a blockquote section.
    // Trim trailing whitespace and newlines in the string content
    while ([mutableAttributedString.string hasSuffixCharacterFromSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]])
    {
        [mutableAttributedString deleteCharactersInRange:NSMakeRange(mutableAttributedString.length - 1, 1)];
    }
    
    // New lines may have also been introduced by the paragraph style
    // Make sure the last paragraph style has no spacing
    [mutableAttributedString enumerateAttributesInRange:NSMakeRange(0, mutableAttributedString.length) options:(NSAttributedStringEnumerationReverse) usingBlock:^(NSDictionary *attrs, NSRange range, BOOL *stop) {
        
        if (attrs[NSParagraphStyleAttributeName])
        {
            NSString *subString = [mutableAttributedString.string substringWithRange:range];
            NSArray *components = [subString componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
            
            NSMutableDictionary *updatedAttrs = [NSMutableDictionary dictionaryWithDictionary:attrs];
            NSMutableParagraphStyle *paragraphStyle = [updatedAttrs[NSParagraphStyleAttributeName] mutableCopy];
            paragraphStyle.paragraphSpacing = 0;
            updatedAttrs[NSParagraphStyleAttributeName] = paragraphStyle;
            
            if (components.count > 1)
            {
                NSString *lastComponent = components.lastObject;
                
                NSRange range2 = NSMakeRange(range.location, range.length - lastComponent.length);
                [mutableAttributedString setAttributes:attrs range:range2];
                
                range2 = NSMakeRange(range2.location + range2.length, lastComponent.length);
                [mutableAttributedString setAttributes:updatedAttrs range:range2];
            }
            else
            {
                [mutableAttributedString setAttributes:updatedAttrs range:range];
            }
        }
        
        // Check only the last paragraph
        *stop = YES;
    }];
    
    // Image rendering failed on an exception until we replace the DTImageTextAttachments with a simple NSTextAttachment subclass
    // (thanks to https://github.com/Cocoanetics/DTCoreText/issues/863).
    [mutableAttributedString enumerateAttribute:NSAttachmentAttributeName
                                        inRange:NSMakeRange(0, mutableAttributedString.length)
                                        options:0
                                     usingBlock:^(id value, NSRange range, BOOL *stop) {
                                         
                                         if ([value isKindOfClass:DTImageTextAttachment.class])
                                         {
                                             DTImageTextAttachment *attachment = (DTImageTextAttachment*)value;
                                             NSTextAttachment *textAttachment = [[NSTextAttachment alloc] init];
                                             if (attachment.image)
                                             {
                                                 textAttachment.image = attachment.image;
                                                 
                                                 CGRect frame = textAttachment.bounds;
                                                 frame.size = attachment.displaySize;
                                                 textAttachment.bounds = frame;
                                             }
                                             // Note we remove here attachment without image.
                                             NSAttributedString *attrStringWithImage = [NSAttributedString attributedStringWithAttachment:textAttachment];
                                             [mutableAttributedString replaceCharactersInRange:range withAttributedString:attrStringWithImage];
                                         }
                                     }];
    
    return mutableAttributedString;
}

+ (NSString*)cssToMarkBlockquotes
{
    return [NSString stringWithFormat:@"blockquote {background: #%lX; display: block;}", (unsigned long)[[self class] rgbValueWithColor:kMXKToolsBlockquoteMarkColor]];
}

+ (NSAttributedString*)removeMarkedBlockquotesArtifacts:(NSAttributedString*)attributedString
{
    NSMutableAttributedString *mutableAttributedString = [[NSMutableAttributedString alloc] initWithAttributedString:attributedString];

    // Enumerate all sections marked thanks to `cssToMarkBlockquotes`
    // and apply our own attribute instead.

    // According to blockquotes in the string, DTCoreText can apply 2 policies:
    //     - define a `DTTextBlocksAttribute` attribute on a <blockquote> block
    //     - or, just define a `NSBackgroundColorAttributeName` attribute

    // `DTTextBlocksAttribute` case
    [attributedString enumerateAttribute:DTTextBlocksAttribute
                                 inRange:NSMakeRange(0, attributedString.length)
                                 options:0
                              usingBlock:^(id  _Nullable value, NSRange range, BOOL * _Nonnull stop)
     {
         if ([value isKindOfClass:NSArray.class])
         {
             NSArray *array = (NSArray*)value;
             if (array.count > 0 && [array[0] isKindOfClass:DTTextBlock.class])
             {
                 DTTextBlock *dtTextBlock = (DTTextBlock *)array[0];
                 if ([dtTextBlock.backgroundColor isEqual:kMXKToolsBlockquoteMarkColor])
                 {
                     // Apply our own attribute
                     [mutableAttributedString addAttribute:kMXKToolsBlockquoteMarkAttribute value:@(YES) range:range];

                     // Fix a boring behaviour where DTCoreText add a " " string before a string corresponding
                     // to an HTML blockquote. This " " string has ParagraphStyle.headIndent = 0 which breaks
                     // the blockquote block indentation
                     if (range.location > 0)
                     {
                         NSRange prevRange = NSMakeRange(range.location - 1, 1);

                         NSRange effectiveRange;
                         NSParagraphStyle *paragraphStyle = [attributedString attribute:NSParagraphStyleAttributeName
                                                                                atIndex:prevRange.location
                                                                         effectiveRange:&effectiveRange];

                         // Check if this is the " " string
                         if (paragraphStyle && effectiveRange.length == 1 && paragraphStyle.firstLineHeadIndent != 25)
                         {
                             // Fix its paragraph style
                             NSMutableParagraphStyle *newParagraphStyle = [paragraphStyle mutableCopy];
                             newParagraphStyle.firstLineHeadIndent = 25.0;
                             newParagraphStyle.headIndent = 25.0;

                             [mutableAttributedString addAttribute:NSParagraphStyleAttributeName value:newParagraphStyle range:prevRange];
                         }
                     }
                 }
             }
         }
     }];

    // `NSBackgroundColorAttributeName` case
    [mutableAttributedString enumerateAttribute:NSBackgroundColorAttributeName
                                        inRange:NSMakeRange(0, mutableAttributedString.length)
                                        options:0
                                     usingBlock:^(id value, NSRange range, BOOL *stop)
     {

         if ([value isKindOfClass:UIColor.class] && [(UIColor*)value isEqual:kMXKToolsBlockquoteMarkColor])
         {
             // Remove the marked background
             [mutableAttributedString removeAttribute:NSBackgroundColorAttributeName range:range];

             // And apply our own attribute
             [mutableAttributedString addAttribute:kMXKToolsBlockquoteMarkAttribute value:@(YES) range:range];
         }
     }];

    return mutableAttributedString;
}

+ (NSUInteger)rgbValueWithColor:(UIColor*)color
{
    CGFloat red, green, blue, alpha;
    
    [color getRed:&red green:&green blue:&blue alpha:&alpha];
    
    NSUInteger rgbValue = ((int)(red * 255) << 16) + ((int)(green * 255) << 8) + (blue * 255);
    
    return rgbValue;
}

+ (void)enumerateMarkedBlockquotesInAttributedString:(NSAttributedString*)attributedString usingBlock:(void (^)(NSRange range, BOOL *stop))block
{
    [attributedString enumerateAttribute:kMXKToolsBlockquoteMarkAttribute
                                 inRange:NSMakeRange(0, attributedString.length)
                                 options:0
                              usingBlock:^(id  _Nullable value, NSRange range, BOOL * _Nonnull stop)
     {
         if ([value isKindOfClass:NSNumber.class] && ((NSNumber*)value).boolValue)
         {
             block(range, stop);
         }
     }];
}

@end
