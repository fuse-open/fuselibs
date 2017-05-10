#include <uObjC.Foreign.h>

namespace FuseVideoImpl
{

	void * allocateVideoState();
	void freeVideoState(void * videoState);
	void initialize(void * videoState, NSString * uri, uDelegate * loadedCallback, uDelegate * errorCallback);
	double getDuration(void * videoState);
	double getPosition(void * videoState);
	void setPosition(void * videoState, double position);
	float getVolume(void * videoState);
	void setVolume(void * videoState, float volume);
	int getWidth(void * videoState);
	int getHeight(void * videoState);
	void play(void * videoState);
	void pause(void * videoState);
	int updateTexture(void * videoState);
	void setErrorHandler(void * videoState, uDelegate * errorHandler);
	int getRotation(void * videoState);

}
