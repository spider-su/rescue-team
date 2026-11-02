import subprocess,time,pathlib,json,sys,math
OUT=pathlib.Path(__file__).resolve().parent;ROOT=OUT.parents[2]
ADB=['/opt/homebrew/share/android-commandlinetools/platform-tools/adb','-s','emulator-5554']
def sh(*a):return subprocess.check_output(ADB+['shell',*map(str,a)])
def tap(x,y,wait=.65):sh('input','tap',round(x),round(y));time.sleep(wait)
def shot(n):(OUT/(n+'.png')).write_bytes(subprocess.check_output(ADB+['exec-out','screencap','-p']))
def read(name):return sh('run-as','com.spidersu.rescueteam','cat','files/'+name).decode()
def cell(n,x,y):
 p=next(p for p in ROOT.glob('levels/**/*.json') if json.loads(p.read_text())['id']==n);d=json.loads(p.read_text());w=len(d['rows'][0]);h=len(d['rows']);bw,bh=1040,1056;top=746
 rotated=w>h
 cols,rows=(h,w) if rotated else (w,h)
 step=math.floor(min((bw/1.5-28)/cols,(bh/1.5-28)/rows))*1.5
 dx,dy=(h-1-y,x) if rotated else (x,y)
 return 20+(bw-cols*step)/2+(dx+.5)*step,top+(bh-rows*step)/2+(dy+.5)*step
if __name__=='__main__':
 n=sys.argv[1]; fixtures={}
 for p in (ROOT/'tests/fixtures').glob('*solutions.json'):fixtures.update(json.loads(p.read_text()))
 for i,(role,x,y) in enumerate(fixtures[n]):
  three=any('R' in row for row in json.loads(next(p for p in ROOT.glob('levels/**/*.json') if json.loads(p.read_text())['id']==n).read_text())['rows'])
  rx=({'firefighter':180,'engineer':540,'ranger':900}[role] if three else (270 if role=='firefighter' else 810))
  tap(rx,645,.2)
  cx,cy=cell(n,x,y);tap(cx,cy,2.8)
  shot(f'mission{n}-step{i+1:02d}')
 progress=json.loads(read('rescue_progress_v1.json'));assert n in progress['best'],progress
 print('PASS',n,'saved moves',progress['best'][n],flush=True)
 (OUT/f'mission{n}-progress.json').write_text(json.dumps(progress,indent=2)+'\n')
