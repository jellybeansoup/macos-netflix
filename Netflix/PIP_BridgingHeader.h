#import <AppKit/AppKit.h>

@protocol PIPViewControllerDelegate;

@interface PIPViewController : NSViewController

@property (nonatomic, copy, nullable) NSString *name;
@property (nonatomic, weak, nullable) id<PIPViewControllerDelegate> delegate;
@property (nonatomic, weak, nullable) NSWindow *replacementWindow;
@property (nonatomic, weak, nullable) NSView *replacementView;
@property (nonatomic) NSRect replacementRect;
@property (nonatomic) bool playing;
@property (nonatomic) bool userCanResize;
@property (nonatomic) NSSize aspectRatio;
@property (nonatomic) NSSize minSize;
@property (nonatomic) NSSize maxSize;

- (void)presentViewControllerAsPictureInPicture:(NSViewController * _Nonnull)viewController;

@end

@protocol PIPViewControllerDelegate <NSObject>

@optional
- (BOOL)pipShouldClose:(PIPViewController * _Nonnull)pip;
- (void)pipWillClose:(PIPViewController * _Nonnull)pip;
- (void)pipDidClose:(PIPViewController * _Nonnull)pip;
- (void)pipActionPlay:(PIPViewController * _Nonnull)pip;
- (void)pipActionPause:(PIPViewController * _Nonnull)pip;
- (void)pipActionStop:(PIPViewController * _Nonnull)pip;

@end
