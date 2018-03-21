#include "sdl2_cocoa.h"
#include "mruby.h"
#include "mruby/value.h"
#include "mruby/string.h"
#include "mruby/data.h"
#include "sdl2.h"
#include "sdl2_video.h"
#include <SDL_syswm.h>
#import <Cocoa/Cocoa.h>
#import <objc/runtime.h>

void blackmagic_drawRect(id self, SEL _cmd, NSRect dirtyRect)
{
  [self blackmagic_drawRect:dirtyRect];
  [[NSColor clearColor] setFill];
  NSRectFillUsingOperation(dirtyRect,NSCompositingOperationCopy);
}

static mrb_value mrb_sdl2_cocoa_change_transparency(mrb_state *mrb, mrb_value self)
{
  SDL_Window *window = mrb_sdl2_video_window_get_ptr(mrb, self);
  SDL_SysWMinfo info;
  SDL_VERSION(&info.version);
  if( SDL_GetWindowWMInfo(window, &info) == false ) {
    printf("SDL_GetWindowWMInfo from %d FAILED: %s\n", window, SDL_GetError());
    return mrb_nil_value();
  }
  NSWindow *nswindow = info.info.cocoa.window;

  @autoreleasepool {
    // SDLView#drawRect fills black since SDL 2.0.8
    // this approach overrides that behavior in order to transparent window.
    NSString *typeString = [NSString stringWithFormat:@"v@:%s", @encode(NSRect)];
    Class sdlView = NSClassFromString(@"SDLView");
    class_addMethod(sdlView, @selector(blackmagic_drawRect:), (IMP)blackmagic_drawRect, [typeString UTF8String]);
    Method original = class_getInstanceMethod(sdlView, @selector(drawRect:));
    Method blackmagic = class_getInstanceMethod(sdlView, @selector(blackmagic_drawRect:));
    method_exchangeImplementations(original, blackmagic);

    [nswindow setOpaque:NO];
    [nswindow setBackgroundColor:[NSColor clearColor]];

    NSOpenGLContext* context = [NSOpenGLContext currentContext];
    GLint opaque = 0;
    [context setValues:&opaque forParameter:NSOpenGLCPSurfaceOpacity];

    return self;
  }
}

static mrb_value mrb_sdl2_cocoa_on_top(mrb_state *mrb, mrb_value self)
{
  SDL_Window *window = mrb_sdl2_video_window_get_ptr(mrb, self);
  SDL_SysWMinfo info;
  SDL_VERSION(&info.version);
  if( SDL_GetWindowWMInfo(window, &info) == false ) {
    return mrb_nil_value();
  }
  NSWindow *nswindow = info.info.cocoa.window;

  @autoreleasepool {
    [nswindow setLevel:NSFloatingWindowLevel];
  }

  return self;
}

SDL_HitTestResult hitTestDraggable(SDL_Window *win, const SDL_Point* area, void* data)
{
  return SDL_HITTEST_DRAGGABLE;
}

static mrb_value mrb_sdl2_cocoa_draggable(mrb_state *mrb, mrb_value self)
{
  mrb_bool draggable;
  mrb_get_args(mrb, "b", &draggable);
  SDL_Window *window = mrb_sdl2_video_window_get_ptr(mrb, self);
  if(draggable){
    SDL_SetWindowHitTest(window,hitTestDraggable,NULL);
  }else{
    SDL_SetWindowHitTest(window,NULL,NULL);
  }
  return self;
}

void mrb_mruby_sdl2_cocoa_gem_init(mrb_state *mrb) {
  struct RClass *mod_Video;
  struct RClass *class_Window;
  mod_Video = mrb_module_get_under(mrb, mod_SDL2,  "Video");
  class_Window = mrb_class_get_under(mrb, mod_Video, "Window");
  mrb_define_method(mrb, class_Window, "change_transparency", mrb_sdl2_cocoa_change_transparency, MRB_ARGS_NONE() );
  mrb_define_method(mrb, class_Window, "on_top", mrb_sdl2_cocoa_on_top, MRB_ARGS_NONE() );
  mrb_define_method(mrb, class_Window, "draggable=", mrb_sdl2_cocoa_draggable, MRB_ARGS_REQ(1) );
}

void mrb_mruby_sdl2_cocoa_gem_final(mrb_state *mrb) {
}
