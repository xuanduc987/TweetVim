
let s:backup = []

let s:buf_name = '[tweetvim]'
"
"
"
function! tweetvim#buffer#load(method, args, title, tweets, ...)

  let param = a:0 ? a:1 : {}
  call s:switch_buffer(param)
  call s:pre_process(param)
  call s:process(a:method, a:args, a:title, a:tweets, param)
  call s:post_process(param)

  if !has_key(param, 'split')
    call s:backup(a:method, a:args, a:title, a:tweets, param)
  endif

  let b:tweetvim_bufno = -1

endfunction
"
"
"
function! tweetvim#buffer#previous()
  if len(s:backup) <= (b:tweetvim_bufno * -1)
    echo 'no previous'
    return
  endif

  let bufno = b:tweetvim_bufno - 1
  let pre   = s:backup[bufno]

  call tweetvim#buffer#load(pre.method, pre.args, pre.title, pre.tweets, pre.param)
  " TODO
  let s:backup = s:backup[0:-2]
  let b:tweetvim_bufno = bufno
  echo 'previous : ' . string(b:tweetvim_bufno)
endfunction
"
"
"
function! tweetvim#buffer#next()
  if b:tweetvim_bufno == -1
    echo 'no next'
    return
  endif

  let bufno = b:tweetvim_bufno + 1
  let pre   = s:backup[bufno]

  call tweetvim#buffer#load(pre.method, pre.args, pre.title, pre.tweets, pre.param)
  " TODO
  let s:backup = s:backup[0:-2]
  let b:tweetvim_bufno = bufno
  echo 'next : ' . string(b:tweetvim_bufno)
endfunction
"
"
"
function! s:backup(method, args, title, tweets, param)
  call add(s:backup, {
        \ 'method' : a:method,
        \ 'args'   : a:args,
        \ 'title'  : a:title,
        \ 'tweets' : a:tweets,
        \ 'param'  : a:param,
        \ })
  " truncate
  if len(s:backup) > 5
    let s:backup = s:backup[1:]
  endif
endfunction
"
"
"
function! s:switch_buffer(param)
  let buf_name = get(a:param, 'buf_name', s:buf_name)
  let exist_win = 0

  " TODO : find window or buffer
  " buf_name is [tweetvim] or [tweetvim - in_replly_to]
  if buf_name == s:buf_name
    let winnr = 1
    while winnr <= winnr('$')
      if getbufvar(winbufnr(winnr), '&filetype') ==# 'tweetvim'
        execute winnr 'wincmd w'
        let exist_win = 1
        break
      endif
      let winnr += 1
    endwhile
  endif

  if !exist_win
    let bufno = s:bufnr(escape(buf_name, '*[]?{},'))
    if bufno > 0
      execute 'buffer ' . bufno
    else
      " TODO
      if get(a:param, 'split', 0)
        split
      endif
      execute 'edit! ' . buf_name
    endif
  endif
endfunction
"
"
"
function! s:pre_process(param)
  setlocal noswapfile
  setlocal modifiable
  setlocal buftype=nofile
  setfiletype tweetvim
  silent %delete _
endfunction
"
"
"
function! s:process(method, args, title, tweets, param)
  let b:tweetvim_method = a:method
  let b:tweetvim_args   = a:args
  let b:tweetvim_status_cache = {}

  call s:append_tweets(a:tweets, b:tweetvim_status_cache)

  let title  = '[tweetvim]  - ' . a:title
  call append(0, title)
  normal dd
  :0

  if get(a:param, 'split', 0)
    execute string(len(a:tweets) * 2 + 2) . 'wincmd _'
  endif
endfunction
"
"
"
function! s:post_process(param)
  setlocal nomodified
  setlocal nomodifiable
endfunction
"
"
"
function! s:append_tweets(tweets, cache)
  let separator = tweetvim#util#separator('-')
  " TODO : new separator
  let is_new    = 0
  for tweet in a:tweets
    " add new or default separator
    if is_new && !has_key(tweet, 'is_new')
      call append(line('$') - 1, tweetvim#util#separator(' '))
      let is_new = 0
    else
      call append(line('$') - 1, separator)
    endif

    call append(line('$') - 1, s:format(tweet))
    " cache tweet by line no
    let a:cache[line(".")] = tweet
  endfor

endfunction
"
"
"
function! s:bufnr(buf_name)
  return bufexists(substitute(substitute(a:buf_name, '[', '\\[', 'g'), ']', '\\]', 'g') . '$')
endfunction
"
"
"
function! s:format(tweet)
  let text = a:tweet.text
  let text = substitute(text , '
  let text = substitute(text , '\n' , '' , 'g')
  let text = tweetvim#util#unescape(text)

  let str  = tweetvim#util#padding(a:tweet.user.screen_name, 15) . ' : '
  if a:tweet.favorited
    let str .= '★ '
  endif
  let str .= text

  return str
endfunction