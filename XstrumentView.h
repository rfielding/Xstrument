//
//  XstrumentView.h
//  Xstrument
//
/*
The Samchillian is patented by Leon Gruenbaum. 
I have gotten permission to make this application available for general consumption. 
Refer to the original Samchillian 
http://www.samchillian.com 
if you have any questions about whether you need to be concerned about copyright
 or patent issues (such as if you have implemented something similar yourself). 
Like the official Samchillian software, this is only for non commercial use, 
which means that you have no right to sell this or modified copies of this 
software without explicit permission.  
*/
//

#import <Cocoa/Cocoa.h>

/*
   The OpenGL surface whose job it is to get key events to hand down to the PortableUI
 */
@interface XstrumentView : NSOpenGLView {
}
-(void) invalidateLoop;
-(void) intervalTick;
@end
