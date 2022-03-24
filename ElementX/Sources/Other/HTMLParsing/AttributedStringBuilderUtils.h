//
//  AttributedStringBuilderUtils.h
//  ElementX
//
//  Created by Stefan Ceriu on 23/03/2022.
//  Copyright © 2022 Element. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT NSString *const kMXKToolsBlockquoteMarkAttribute;

@interface AttributedStringBuilderUtils : NSObject

+ (NSString*)cssToMarkBlockquotes;

+ (NSAttributedString *)removeDTCoreTextArtifacts:(NSAttributedString *)attributedString;

+ (NSAttributedString*)removeMarkedBlockquotesArtifacts:(NSAttributedString*)attributedString;

+ (NSAttributedString*)createLinks:(NSAttributedString*)attributedString;

@end

NS_ASSUME_NONNULL_END
