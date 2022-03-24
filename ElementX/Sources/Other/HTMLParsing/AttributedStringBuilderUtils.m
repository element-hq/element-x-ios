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

static NSRegularExpression *userIdRegex;
static NSRegularExpression *roomIdRegex;
static NSRegularExpression *roomAliasRegex;
static NSRegularExpression *eventIdRegex;
static NSRegularExpression *groupIdRegex;
static NSRegularExpression *httpLinksRegex;
static NSRegularExpression *htmlTagsRegex;

#define MATRIX_HOMESERVER_DOMAIN_REGEX                            @"[A-Z0-9]+((\\.|\\-)[A-Z0-9]+){0,}(:[0-9]{2,5})?"

NSString *const kMXToolsRegexStringForMatrixUserIdentifier      = @"@[\\x21-\\x39\\x3B-\\x7F]+:" MATRIX_HOMESERVER_DOMAIN_REGEX;
NSString *const kMXToolsRegexStringForMatrixRoomAlias           = @"#[A-Z0-9._%#@=+-]+:" MATRIX_HOMESERVER_DOMAIN_REGEX;
NSString *const kMXToolsRegexStringForMatrixRoomIdentifier      = @"![A-Z0-9]+:" MATRIX_HOMESERVER_DOMAIN_REGEX;
NSString *const kMXToolsRegexStringForMatrixEventIdentifier     = @"\\$[A-Z0-9]+:" MATRIX_HOMESERVER_DOMAIN_REGEX;
NSString *const kMXToolsRegexStringForMatrixEventIdentifierV3   = @"\\$[A-Z0-9\\/+]+";
NSString *const kMXToolsRegexStringForMatrixGroupIdentifier     = @"\\+[A-Z0-9=_\\-./]+:" MATRIX_HOMESERVER_DOMAIN_REGEX;

@implementation AttributedStringBuilderUtils

+ (void)initialize
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        userIdRegex = [NSRegularExpression regularExpressionWithPattern:kMXToolsRegexStringForMatrixUserIdentifier options:NSRegularExpressionCaseInsensitive error:nil];
        roomIdRegex = [NSRegularExpression regularExpressionWithPattern:kMXToolsRegexStringForMatrixRoomIdentifier options:NSRegularExpressionCaseInsensitive error:nil];
        roomAliasRegex = [NSRegularExpression regularExpressionWithPattern:kMXToolsRegexStringForMatrixRoomAlias options:NSRegularExpressionCaseInsensitive error:nil];
        eventIdRegex = [NSRegularExpression regularExpressionWithPattern:kMXToolsRegexStringForMatrixEventIdentifier options:NSRegularExpressionCaseInsensitive error:nil];
        groupIdRegex = [NSRegularExpression regularExpressionWithPattern:kMXToolsRegexStringForMatrixGroupIdentifier options:NSRegularExpressionCaseInsensitive error:nil];
        
        httpLinksRegex = [NSRegularExpression regularExpressionWithPattern:@"(?i)\\b(https?://.*)\\b" options:NSRegularExpressionCaseInsensitive error:nil];
        htmlTagsRegex  = [NSRegularExpression regularExpressionWithPattern:@"<(\\w+)[^>]*>" options:NSRegularExpressionCaseInsensitive error:nil];
    });
}

+ (NSString*)cssToMarkBlockquotes
{
    return [NSString stringWithFormat:@"blockquote {background: #%lX; display: block;}", (unsigned long)[[self class] rgbValueWithColor:kMXKToolsBlockquoteMarkColor]];
}

+ (NSUInteger)rgbValueWithColor:(UIColor*)color
{
    CGFloat red, green, blue, alpha;
    
    [color getRed:&red green:&green blue:&blue alpha:&alpha];
    
    NSUInteger rgbValue = ((int)(red * 255) << 16) + ((int)(green * 255) << 8) + (blue * 255);
    
    return rgbValue;
}

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

+ (NSAttributedString*)createLinks:(NSAttributedString*)attributedString
{
    if (!attributedString)
    {
        return nil;
    }
    
    NSMutableAttributedString *postRenderAttributedString;
    
    [[self class] createHTTPLinksInAttributedString:attributedString withWorkingAttributedString:&postRenderAttributedString];
    [[self class] createLinksInAttributedString:attributedString matchingRegex:userIdRegex withWorkingAttributedString:&postRenderAttributedString];
    [[self class] createLinksInAttributedString:attributedString matchingRegex:roomIdRegex withWorkingAttributedString:&postRenderAttributedString];
    [[self class] createLinksInAttributedString:attributedString matchingRegex:roomAliasRegex withWorkingAttributedString:&postRenderAttributedString];
    [[self class] createLinksInAttributedString:attributedString matchingRegex:eventIdRegex withWorkingAttributedString:&postRenderAttributedString];
    [[self class] createLinksInAttributedString:attributedString matchingRegex:groupIdRegex withWorkingAttributedString:&postRenderAttributedString];
    
    return postRenderAttributedString ? postRenderAttributedString : attributedString;
}

+ (void)createHTTPLinksInAttributedString:(NSAttributedString*)attributedString
              withWorkingAttributedString:(NSMutableAttributedString* __autoreleasing *)mutableAttributedString
{
    // Enumerate each string matching the regex
    [httpLinksRegex enumerateMatchesInString:attributedString.string options:0 range:NSMakeRange(0, attributedString.length) usingBlock:^(NSTextCheckingResult *match, NSMatchingFlags flags, BOOL *stop) {
        
        // Do not create a link if there is already one on the found match
        __block BOOL hasAlreadyLink = NO;
        [attributedString enumerateAttributesInRange:match.range options:0 usingBlock:^(NSDictionary<NSString *,id> * _Nonnull attrs, NSRange range, BOOL * _Nonnull stop) {
            
            if (attrs[NSLinkAttributeName])
            {
                hasAlreadyLink = YES;
                *stop = YES;
            }
        }];
        
        if (!hasAlreadyLink)
        {
            // Create the output string only if it is necessary because attributed strings cost CPU
            if (!*mutableAttributedString)
            {
                *mutableAttributedString = [[NSMutableAttributedString alloc] initWithAttributedString:attributedString];
            }
            
            // Make the link clickable
            // Caution: We need here to escape the non-ASCII characters (like '#' in room alias)
            // to convert the link into a legal URL string.
            NSString *link = [attributedString.string substringWithRange:match.range];
            link = [link stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
            [*mutableAttributedString addAttribute:NSLinkAttributeName value:link range:match.range];
            [*mutableAttributedString addAttribute:NSForegroundColorAttributeName value:UIColor.blueColor range:match.range];
        }
    }];
}

+ (void)createLinksInAttributedString:(NSAttributedString*)attributedString
                        matchingRegex:(NSRegularExpression*)regex
          withWorkingAttributedString:(NSMutableAttributedString* __autoreleasing *)mutableAttributedString
{
    __block NSArray *linkMatches;
    
    // Enumerate each string matching the regex
    [regex enumerateMatchesInString:attributedString.string options:0 range:NSMakeRange(0, attributedString.length) usingBlock:^(NSTextCheckingResult *match, NSMatchingFlags flags, BOOL *stop) {
        
        // Do not create a link if there is already one on the found match
        __block BOOL hasAlreadyLink = NO;
        [attributedString enumerateAttributesInRange:match.range options:0 usingBlock:^(NSDictionary<NSString *,id> * _Nonnull attrs, NSRange range, BOOL * _Nonnull stop) {
            
            if (attrs[NSLinkAttributeName])
            {
                hasAlreadyLink = YES;
                *stop = YES;
            }
        }];
        
        // Do not create a link if the match is part of an http link.
        // The http link will be automatically generated by the UI afterwards.
        // So, do not break it now by adding a link on a subset of this http link.
        if (!hasAlreadyLink)
        {
            if (!linkMatches)
            {
                // Search for the links in the string only once
                // Do not use NSDataDetector with NSTextCheckingTypeLink because is not able to
                // manage URLs with 2 hashes like "https://matrix.to/#/#matrix:matrix.org"
                // Such URL is not valid but web browsers can open them and users C+P them...
                // NSDataDetector does not support it but UITextView and UIDataDetectorTypeLink
                // detect them when they are displayed. So let the UI create the link at display.
                linkMatches = [httpLinksRegex matchesInString:attributedString.string options:0 range:NSMakeRange(0, attributedString.length)];
            }
            
            for (NSTextCheckingResult *linkMatch in linkMatches)
            {
                // If the match is fully in the link, skip it
                if (NSIntersectionRange(match.range, linkMatch.range).length == match.range.length)
                {
                    hasAlreadyLink = YES;
                    break;
                }
            }
        }
        
        if (!hasAlreadyLink)
        {
            // Create the output string only if it is necessary because attributed strings cost CPU
            if (!*mutableAttributedString)
            {
                *mutableAttributedString = [[NSMutableAttributedString alloc] initWithAttributedString:attributedString];
            }
            
            // Make the link clickable
            // Caution: We need here to escape the non-ASCII characters (like '#' in room alias)
            // to convert the link into a legal URL string.
            NSString *link = [attributedString.string substringWithRange:match.range];
            link = [link stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
            [*mutableAttributedString addAttribute:NSLinkAttributeName value:link range:match.range];
            [*mutableAttributedString addAttribute:NSForegroundColorAttributeName value:UIColor.blueColor range:match.range];
        }
    }];
}

@end
