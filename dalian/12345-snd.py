#!/usr/bin/python3
# coding: utf-8

from __future__ import print_function
import logging
logging.basicConfig(level=logging.INFO) # 需要调试时使用 level=logging.DEBUG

import base64
from bs4 import BeautifulSoup
import datetime
from collections import deque
from datetime import datetime, time
import requests
from time import sleep
import sys
import traceback
import time
import urllib3

from urllib3.exceptions import InsecureRequestWarning
urllib3.disable_warnings(InsecureRequestWarning)

from selenium import webdriver
from selenium.webdriver.common.action_chains import ActionChains
from selenium.webdriver.common.by import By
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.chrome.service import Service as ChromeService
from selenium.webdriver import DesiredCapabilities

from webdriver_manager.chrome import ChromeDriverManager

# 对应 SSL
import ssl
ssl._create_default_https_context = ssl._create_unverified_context

# 替换以下信息
LOGIN_URL = 'https://fm.xarvio.com/jp/ja_jp/login' # 系统登录网址
ID        = 'yangguo2003@mineo.jp' # 用户名
PW        = 'yangguo2003' # 密码
TGT_PAGE  = 'https://fm.xarvio.com/jp/ja_jp/farm/dashboard' # 查询待分发页面的网址 (target)
POST_URL  = <POST_URL> # 后台网址

# 浏览器 browser 的选项
options = Options()

# 可以指定浏览器
# options.binary_location = r"C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
options.add_argument('--headless')
options.add_argument('--no-sandbox')
options.add_argument('--disable-gpu')
options.add_argument('--ignore-certificate-errors')
options.add_argument('--window-size=1920,1080') # Unable to locate element:

# 生成模拟浏览器 browser
capabilities = DesiredCapabilities.CHROME
new_driver = ChromeDriverManager().install()
service = ChromeService(executable_path=new_driver)
browser = webdriver.Chrome(service=service, options=options, desired_capabilities=capabilities)

# 页面访问delay 1.5秒
browser.implicitly_wait(2.5)

# 取得登录时时间
start = datetime.now()

try:
  browser.delete_all_cookies()
  browser.get(LOGIN_URL)  # 打开登录页面
  sleep(5)

  # 确认 cookies
  allCookies = browser.get_cookies()
  # 调试取得的 cookies
  logging.debug(allCookies)

  # 在登录页面寻找 用户名，密码，登录按钮的位置
  user_input 		= browser.find_element(By.XPATH, '//input[@data-selenium="login-email-input"]')
  user_password = browser.find_element(By.XPATH, '//input[@data-selenium="login-password-input"]')
  login         = browser.find_element(By.XPATH, '//button[@data-selenium="login-submit-button"]')

  '''
  # XPATH 多种方式
  user_input    = browser.find_element(By.XPATH, '//*[@id="user_input"]/input')
  user_password = browser.find_element(By.XPATH, '//*[@id="password_input"]/input')
  login         = browser.find_element(By.XPATH, '//*[@id="new_login"]/form/p[2]/input')
  '''

  # 清空内容
  user_input.clear()
  user_password.clear()

  # 输入 用户名，密码
  user_input.send_keys(ID)
  user_password.send_keys(PW)

  # 点击 登录按钮
  login.click()
  sleep(10)

  handle_array = browser.window_handles
  logging.debug(len(handle_array))
  # browser.switch_to.window(handle_array[1])

  # 登录成功后，继续打开「待分发页面 html」
  browser.get(TGT_PAGE)
  sleep(2)

  # 取得「待分发页面 html」代码
  page_source = browser.page_source
  # 经base64编码
  page_source_b64 = base64.b64encode(page_source.encode()).decode()

  # 调试用(可以注释掉 from ↓)
  with open("tgt.html", 'w', encoding="utf-8") as page:
    page.write(page_source)

  w = browser.execute_script('return document.body.scrollWidth')
  h = browser.execute_script('return document.body.scrollHeight')
  logging.info("{}, {}".format(w, h))
  browser.set_window_size(w, 1280)  # Unable to locate element:
  browser.save_screenshot('screenshot.png')
  # 调试用(可以注释掉 till　↑)

  # 将经base64编码后「待分发页面 html」发送至后台解析
  headers = {"Content-Type": "application/x-www-form-urlencoded"}
  data = {
    "foo": "foo-val",
    "bar": "bar-val",
    "htm": page_source_b64
  }

  logging.debug(page_source_b64)
  logging.debug(type(page_source_b64))

  r = requests.post(url=POST_URL, data=data, headers=headers, timeout=(3.0, 30.5))
  logging.info(r)

except Exception as e:
  logging.error("error: {0}".format(e), file=sys.stderr)
  # traceback.print_exc()
  exitCode = 2

finally:
  logging.info("Quitting Selenium WebDriver")

  # 确保清空 cookies
  browser.delete_all_cookies()
  browser.close()
  browser.quit()

  logging.info("Finished: {}".format(datetime.now() - start))

