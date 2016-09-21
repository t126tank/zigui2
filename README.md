
# git part

make .gitignore
git init
git add README.md
git commit -m "first commit"
git remote add origin git@github.com:username/project.git
git remote add origin https://github.com/username/project.git
git remote set-url origin https://username@github.com/username/project.git
git push -u origin master



# nodejs part

$ sudo apt-get update
$ sudo apt-get install nodejs npm

Solution:
$ sudo update-alternatives --install /usr/bin/node node /usr/bin/nodejs 10
$ node -v

From PPA Repo:
$ sudo add-apt-repository ppa:chris-lea/node.js 
$ sudo apt-get update
$ sudo apt-get install nodejs npm
$ node -v

ref: https://main-tank.ssl-lolipop.jp/wp/2016/08/16/nodejs-samples/

# cordova 
Issue:
cordova cannot find module 'bplist-parser'
Solution:
$ sudo npm update -g

$ cordova create testapp com.example.testapp "Test" --copy-from

$ cordova plugin add cordova-plugin-media-capture


# ionic
$ npm install -g cordova ionic
$ npm update -g cordova ionic

Refer to "package.json":
$ sudo npm install

If it is a server:
$ node server


# ADB
export ANDROID_LOG_TAGS="ActivityManager:I MyApp:D *:S"

adb logcat ActivityManager:I MyApp:D *:S
V — 明细 (最低优先级)
D — 调试
I — 信息
W — 警告
E — 错误
F — 严重错误
S — 无记载 (最高优先级，没有什么会被记载)

adb logcat -d -f /sdcard/log.txt

    
