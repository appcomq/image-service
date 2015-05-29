# options = {
#   qiniu_domain:    "http://7xie1v.com1.z0.glb.clouddn.com/", 
#   qiniu_basepath:  "i",
#   uptoken_url:     'http://lifei.com:3000/file_entities/uptoken',

#   browse_button:   'ele id | ele | jquery ele',
#   drag_area:       'ele id | ele | jquery ele',
#   file_list_area:  'ele id | ele | jquery ele',
#   file_progress_callback: FileProgress,

#   auto_start: false,
#   paste_upload: false
# }
class Img4yeUploader
  constructor: (@options)->
    @qiniu_domain   = @options["qiniu_domain"]
    @qiniu_basepath = @options["qiniu_basepath"]
    @uptoken_url    = @options["uptoken_url"]

    @browse_button  = @options["browse_button"]
    @drag_area      = @options["drag_area"]
    @file_list_area = @options["file_list_area"]
    @file_progress_callback = @options["file_progress_callback"] || DefualtImg4yeFileProgress
    @dragdrop = (typeof(@drag_area) != "undefined")
    @file_progresses = {}
    @auto_start   = @options["auto_start"]
    @paste_upload = @options["paste_upload"]

    @_process_browse_button();
    @_process_drag_area();

    @_init();
    @_process_paste_upload()
    @_process_auto_start()

  add_file_by_base64: (base64)->
    if base64.match /^data\:image\//
      blob = dataURLtoBlob base64
      blob.name = "paste-#{(new Date).valueOf()}.png"
      @qiniu.addFile(blob)

  _process_drag_area: ()->
    # 如果 drag_area 是一个 jQuery 对象
    # 就设置 drag_area 是原始的 dom 对象
    if typeof(@drag_area) == "object"
      if typeof(@drag_area.get) == "function"
        @drag_area = @drag_area.get(0)

  _process_browse_button: ()->
    # 如果 browse_button 是一个 jQuery 对象
    # 就设置 browse_button 是原始的 dom 对象
    if typeof(@browse_button) == "undefined"
      @browse_button = "browse_button"
    if typeof(@browse_button) == "object"
      if typeof(@browse_button.get) == "function"
        @browse_button = @browse_button.get(0)

  _init: ()->
    that = this
    @qiniu = Qiniu.uploader
      runtimes: 'html5,flash,html4'
      browse_button: that.browse_button,
      uptoken_url: that.uptoken_url,
      domain: that.qiniu_domain,
      max_file_size: '100mb',
      max_retries: 1,
      dragdrop: @dragdrop,
      drop_element: that.drag_area,
      chunk_size: '4mb',
      auto_start: @auto_start,
      x_vars:
        origin_file_name: (up, file)->
          file.name
      init: 
        FilesAdded: (up, files)->
          plupload.each files, (file)->
            # 同时选择多个文件时才会触发
        BeforeUpload: (up, file)->
          that.file_progresses[file.id] = new that.file_progress_callback(that.file_list_area, file)
          that.file_progresses[file.id].start_upload()
        UploadProgress: (up, file)-> 
          chunk_size = plupload.parseSize(this.getOption('chunk_size'));
          that.file_progresses[file.id].refresh_progress()
          # progress.text "当前进度 #{file.percent}%，速度 #{up.total.bytesPerSec}，#{chunk_size}"
        FileUploaded: (up, file, info)->
          that.file_progresses[file.id].uploaded(info)
        Error: (up, err, errTip)->
          that.file_progresses[err.file.id].upload_error()
        UploadComplete: ()->
          #队列文件处理完毕后,处理相关的事情
        Key: (up, file)->
          # // domain 为七牛空间（bucket)对应的域名，选择某个空间后，可通过"空间设置->基本设置->域名设置"查看获取
          # // uploader 为一个plupload对象，继承了所有plupload的方法，参考http://plupload.com/docs
          ext = file.name.split(".").pop()
          "/#{that.qiniu_basepath}/#{jQuery.randstr()}.#{ext}"

  _process_auto_start: ()->
    if !@auto_start
      @start = ->
        @qiniu.start()

  _process_paste_upload: ()->
    return if !@paste_upload

    # 通过粘贴上传文件
    ###
      粘贴有六种情况：
      1. [√] 在 chrome 下通过软件复制图像数据
      2. [√] 在 chrome 下右键复制网页图片
      3. [×] 在 chrome 下粘贴磁盘文件句柄 ......

      4. [√] 在 firefox 下通过软件复制图像数据
      5. [√] 在 firefox 下右键复制网页图片
      6. [√] 在 firefox 下粘贴磁盘文件句柄
    ###


    # 粘贴剪贴板内容 (chrome)
    # 在 firefox 下，需要在页面放置一个隐藏的 contenteditable = true 的 dom
    paste_dom = jQuery '<div contenteditable></div>'
      .css
        'position': 'absolute'
        'left': -99999
        'top': -99999
      .appendTo jQuery(document.body)
      .focus()

    that = this
    jQuery(document).off 'paste'
    jQuery(document).on 'paste', (evt)=>
      # chrome
      arr = (evt.clipboardData || evt.originalEvent.clipboardData)?.items
      if arr?.length
        return @_deal_chrome_paste arr

      # firefox
      paste_dom.html('').focus()
      setTimeout =>
        paste_dom.find('img').each ->
          $img = jQuery(this)
          that._deal_firefox_paste $img

  _deal_chrome_paste: (arr)->
    console.log 'chrome paste'
    for i in arr
      if i.type.match(/^image\/\w+$/) 
        file = i.getAsFile()
        file.name = "paste-#{(new Date).valueOf()}.png"
        @qiniu.addFile(file) if file

  _deal_firefox_paste: ($img)->
    console.log 'firefox paste'
    src = $img.attr 'src'
    if src.match /^data\:image\//
      blob = dataURLtoBlob src
      blob.name = "paste-#{(new Date).valueOf()}.png"
      @qiniu.addFile(blob)
      return

class DefualtImg4yeFileProgress
  constructor: (@$files_ele, @file)->

  refresh_progress: ->
    console.log("refresh_progress #{@file.percent}%", )

  uploaded: (info)->
    console.log("uploaded #{info}", )

  upload_error: ->
    console.log("upload_error")

  start_upload: ->
    console.log("start_upload")

window.Img4yeUploader = Img4yeUploader