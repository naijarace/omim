#import "MWMCommon.h"
#import "EAGLView.h"
#import "MapsAppDelegate.h"
#import "MWMDirectionView.h"

#import "iosOGLContextFactory.h"

#import "3party/Alohalytics/src/alohalytics_objc.h"

#include "Framework.h"
#include "indexer/classificator_loader.hpp"

#include "platform/platform.hpp"

#include "drape/visual_scale.hpp"

#include "std/bind.hpp"
#include "std/limits.hpp"
#include "std/unique_ptr.hpp"

@implementation EAGLView

namespace
{
// Returns DPI as exact as possible. It works for iPhone, iPad and iWatch.
double getExactDPI(double contentScaleFactor)
{
  float const iPadDPI = 132.f;
  float const iPhoneDPI = 163.f;
  float const mDPI = 160.f;

  switch (UI_USER_INTERFACE_IDIOM())
  {
    case UIUserInterfaceIdiomPhone:
      return iPhoneDPI * contentScaleFactor;
    case UIUserInterfaceIdiomPad:
      return iPadDPI * contentScaleFactor;
    default:
      return mDPI * contentScaleFactor;
  }
}
} //  namespace

// You must implement this method
+ (Class)layerClass
{
  return [CAEAGLLayer class];
}

// The GL view is stored in the nib file. When it's unarchived it's sent -initWithCoder:
- (id)initWithCoder:(NSCoder *)coder
{
  NSLog(@"EAGLView initWithCoder Started");
  self = [super initWithCoder:coder];
  if (self)
    [self initialize];

  NSLog(@"EAGLView initWithCoder Ended");
  return self;
}

- (void)initialize
{
  lastViewSize = CGRectZero;

  // Setup Layer Properties
  CAEAGLLayer * eaglLayer = (CAEAGLLayer *)self.layer;

  eaglLayer.opaque = YES;
  eaglLayer.drawableProperties = @{kEAGLDrawablePropertyRetainedBacking : @NO,
                                   kEAGLDrawablePropertyColorFormat : kEAGLColorFormatRGBA8};

  // Correct retina display support in opengl renderbuffer
  self.contentScaleFactor = [[UIScreen mainScreen] nativeScale];

  m_factory = make_unique_dp<dp::ThreadSafeFactory>(new iosOGLContextFactory(eaglLayer));
}

- (void)createDrapeEngineWithWidth:(int)width height:(int)height
{
  LOG(LINFO, ("EAGLView createDrapeEngine Started"));
  
  Framework::DrapeCreationParams p;
  p.m_surfaceWidth = width;
  p.m_surfaceHeight = height;
  p.m_visualScale = dp::VisualScale(getExactDPI(self.contentScaleFactor));
  p.m_isFirstLaunch = [Alohalytics isFirstSession];

  [self.widgetsManager setupWidgets:p];
  GetFramework().CreateDrapeEngine(make_ref(m_factory), move(p));

  LOG(LINFO, ("EAGLView createDrapeEngine Ended"));
}

- (void)addSubview:(UIView *)view
{
  [super addSubview:view];
  for (UIView * v in self.subviews)
  {
    if ([v isKindOfClass:[MWMDirectionView class]])
    {
      [self bringSubviewToFront:v];
      break;
    }
  }
}

- (void)applyOnSize:(int)width withHeight:(int)height
{
  dispatch_async(dispatch_get_main_queue(), ^
  {
    GetFramework().OnSize(width, height);
    // TODO: Temporary realization of visible viewport, this code must be removed later.
    GetFramework().SetVisibleViewport(m2::RectD(0.0, 0.0, width, height));
    [self.widgetsManager resize:CGSizeMake(width, height)];
    self->_drapeEngineCreated = YES;
  });
}

- (void)onSize:(int)width withHeight:(int)height
{
  int w = width * self.contentScaleFactor;
  int h = height * self.contentScaleFactor;

  if (GetFramework().GetDrapeEngine() == nullptr)
    [self createDrapeEngineWithWidth:w height:h];

  [self applyOnSize:w withHeight:h];
}

- (void)layoutSubviews
{
  if (!CGRectEqualToRect(lastViewSize, self.frame))
  {
    lastViewSize = self.frame;
    CGSize const s = self.bounds.size;
    [self onSize:s.width withHeight:s.height];
  }
  [super layoutSubviews];
}

- (void)deallocateNative
{
  GetFramework().PrepareToShutdown();
  m_factory.reset();
}

- (CGPoint)viewPoint2GlobalPoint:(CGPoint)pt
{
  CGFloat const scaleFactor = self.contentScaleFactor;
  m2::PointD const ptG = GetFramework().PtoG(m2::PointD(pt.x * scaleFactor, pt.y * scaleFactor));
  return CGPointMake(ptG.x, ptG.y);
}

- (CGPoint)globalPoint2ViewPoint:(CGPoint)pt
{
  CGFloat const scaleFactor = self.contentScaleFactor;
  m2::PointD const ptP = GetFramework().GtoP(m2::PointD(pt.x, pt.y));
  return CGPointMake(ptP.x / scaleFactor, ptP.y / scaleFactor);
}

- (void)setPresentAvailable:(BOOL)available
{
  m_factory->CastFactory<iosOGLContextFactory>()->setPresentAvailable(available);
}

- (MWMMapWidgets *)widgetsManager
{
  if (!_widgetsManager)
    _widgetsManager = [[MWMMapWidgets alloc] init];
  return _widgetsManager;
}

@end
