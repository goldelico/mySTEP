/**********************************************************************
**	SHARP Digital Camera Application
**********************************************************************/

#ifndef CAMERA_H
#define CAMERA_H

#include "cameraui.h"
#include <qframe.h>
#include <qimage.h>
#include <qpixmap.h>

#define	MIRROR_MAX	2
#define	DIRECTION_MAX	2

#define	CAMERASTATUS_SHUTTER	0
#define	CAMERASTATUS_MIRROR	1
#define	CAMERASTATUS_CAPTURE	2
#define	CAMERASTATUS_DRVALIVE	3
#define	CAMERASTATUS_MAX	4

#define	CAMERAREMAIN_DISPNO	(1<<0)
#define	CAMERAREMAIN_USE_KB	(1<<1)
#define	CAMERAREMAIN_NOUPDATE	(1<<2)

#define	CAMERAZOOM_CALC(z)	(1<<(z+8))

class CameraIO
{
public:
	CameraIO();
	~CameraIO();
	bool Open(void);
	bool Close(void);
	bool Read(void *buf, size_t count);
	bool Write(const void *buf, size_t count);

	bool IoAvalable(void);
	bool setCaptureFrame(QImage *f, bool r, int w, int h, int z);
	bool setReadMode(int st=-1, int sl=-1, int hr=-1, int vr=-1);
	bool CaptureStart(void);
	bool ShutterLatchClear(void);
	int GetCameraStatus(void);
	bool GetPhotoData(QImage *f);

private:
	int cameraFileHandle;
	int driverReadMode;
};

/*-------------------------------------------------------------------*/
class MyFrame : public QFrame
{
	Q_OBJECT
signals:
	void keyevent(int);
protected:
	void keyPressEvent(QKeyEvent *e) {emit keyevent(e->key());}
	void mousePressEvent(QMouseEvent *) {emit keyevent(Key_Space);}
};

/*-------------------------------------------------------------------*/
class Camera : public CameraBase
{ 
	Q_OBJECT

public:
	Camera(QWidget* parent=0, const char* name=0, WFlags fl=0 );
	~Camera();
	void readConfigs(void);
	void writeConfigs(void);

protected:
	void keyPressEvent(QKeyEvent*);
	void timerEvent(QTimerEvent*);
	void closeEvent(QCloseEvent*);
	void setActiveWindow(void);

public slots:
	void ButtonShutter(void);	/* PushButton0 */
	void ButtonResolution(void);	/* PushButton1 */
	void ButtonQuality(void);	/* PushButton2 */
	void ButtonSaveTo(void);	/* PushButton3 */
	void ButtonDispMode(void);	/* PushButton4 */
	void ButtonMirror(void);	/* PushButton5 */
	void ButtonFullScreen(void);	/* PushButton6 */
	void ButtonSaveDir(void); 	/* PushButton7 */
	void ButtonZoom(void);		/* CheckBox1 */
	void FullScreenEvent(int);	/* fullFrame */

public:
	void CalcFrameRate(void);
	int SetSlowMode(bool s);
	int SetDispMode(int d);
	int SetResolution(int r);
	int SetZoom(int z);
	int SetMirror(int m);
	int SetQuality(int q);
	int SetSaveTo(int s);
	int SetSaveDir(int d);
	void DispRemain(const char *msg=NULL);
	void setFullScreen(bool f);
	int getResolutionSize(int *pw=NULL, int *ph=NULL, bool isFinder=false);
	void ShowTempMsg(const char *msg);

private:
	bool isFullScreen;
	bool doCapture;
	unsigned long frameRateTime;
	unsigned long frameRateCount;
	unsigned long inSavedWait;
	int saveWaitTime;
	int slowCapture;
	int dispmodeMax;
	int dispmode;
	int resolution;
	int resolutionMax;
	int zoom;
	int mirror;
	int quality;
	int quality_normal;
	int quality_fine;
	int saveto;
	int savedirection;
	bool noCheckSDWP;
	int LastFileSerialNo;
	int remainDispMode;
	int finderResolution;
	int LastCameraStatus;
	bool BatteryIsLow;
	bool CameraNotReady;
	bool tryCameraRestart;
	MyFrame *fullFrame;
	QFrame *drawFrame;
	QImage *finder;
	QImage *photo;
	CameraIO *cam;
	QPixmap PixmapMirror[MIRROR_MAX];
	QPixmap PixmapSaveDir[DIRECTION_MAX];
	char SaveFileNamePrefix[16];
	char SaveFileNameSuffix[8];
	char SaveFileFormatID[8];
	char SaveDirNameFormat[8];

/*-------------------------------------------------------------------*/
public:
	bool drawFinder(void);
	bool savePhoto(void);

/*-------------------------------------------------------------------*/
public slots:
	void cardMessage(const QCString &, const QByteArray &);

public:
	void initFileControl(void);
	bool isStorageAvalable(int n, 
		long *pbs=NULL, long *pfr=NULL, long *pal=NULL);
	char *getBaseDirPath(int n, char *dir);
	char *createSaveFileName(int n, char *name, int *serial=NULL);

	unsigned long getMsec(void);
	bool checkBatteryLevel(void);
	bool SetAutoPowerOffMode(int m);
	void updateDocLink(void);
	void keyClickSound(void);
	bool CheckSDWPstatus(void);

private:
	long romFSmagic;
	int currectOffMode;
};

#endif // CAMERA_H

