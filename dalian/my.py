#!/usr/bin/python3
# coding:utf-8

# import pandas as pd
from gtts import gTTS

def tts(txt):
  tts = gTTS(text=txt, lang='zh', slow=True) # zh-TW, zh-CN
  tts.save("./msgs/12345.mp3")

