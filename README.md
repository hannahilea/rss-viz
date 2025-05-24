# rss-blog-viz
[<img alt="Static Badge" src="https://img.shields.io/badge/%F0%9F%AA%B4%20Houseplant%20-x?style=flat&amp;label=Project%20type&amp;color=1E1E1D">]("https://www.hannahilea.com/blog/houseplant-programming")

Scrappy script for generating analysis plots of the type in [this post](https://hannahilea.com/blog/blog-birthday-1/), taking an RSS feed as input.

No tests! No CI! No promised maintenance! 

Usage: 
1. [Install Julia](https://julialang.org/install/)
2. Clone this script: 
    `git clone TODO`
3. Find the RSS feed for your site of interest, e.g., `https://hannahilea.com/rss`

Running locally? Use the path to a local RSS feed and pass in the local root to your site: `TODO foo`

Output:
TODO

There are lots of customization options to, e.g., word cloud generation and custom header/footer removal and plot size; this script is scrappy enough that you'd be better off changing the code directly! Assume that this is *not* a beautifully engineered library that nicely inverts control to the caller. 😅

Oh, and if you want some examples of wordcloud customizations supported by WordCloud.jl library used here, there's a [gallery](https://github.com/guo-yong-zhi/WordCloud-Gallery/blob/main/README.md).
To see the list of available color mappings, do 
```
using WordCloud
using ImageInTerminal
WordCloud.displayschemes()
```
