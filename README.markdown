The First Scroll To Refresh solution using only AppKit and Public APIs!

Introduction
================
ScrollToRefresh is a subclass of NSScrollView that adds a "pull-to-refresh" feel to the "elastic" area of NSScrollview. 

![ScrollToRefresh in action](https://github.com/alexzielenski/ScrollToRefresh/raw/master/screenshot.png "Scroll To Refresh")

How it works
================
The secret is actually knowing how scroll views work. When you scroll, the clip view offsets the origin of its `-bounds` so any subview within the clipview will scroll. It also employs a couple of other methods to check the boundaries of the document view which I override to include the refresh view to get a more natural feel.

License
================
ScrollToRefresh is licensed under the MIT license meaning you can do whatever you want with it and I am not responsible for any trouble you get and you must include the license in whatever you use it in.

	//  ScrollToRefresh
	//
	// Copyright (C) 2011 by Alex Zielenski.
	
	// Permission is hereby granted, free of charge, to any person obtaining a copy
	// of this software and associated documentation files (the "Software"), to deal
	// in the Software without restriction, including without limitation the rights
	// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
	// copies of the Software, and to permit persons to whom the Software is
	// furnished to do so, subject to the following conditions:
	//
	// The above copyright notice and this permission notice shall be included in
	// all copies or substantial portions of the Software.
	//
	// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
	// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
	// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
	// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
	// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
	// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
	// THE SOFTWARE.
