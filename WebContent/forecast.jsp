<%@page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" session="false"
import="java.io.*,
        java.net.*,
        java.util.*"%>
<%!
//----------------------------------------------------------------------------
// 配置
static final String SRC_URL           = "http://www.nh121.cn/module?md=qxj&f=forecast";
static final String SRC_CHARSET       = "GB2312";
static final int    FORECAST_DAYS     = 7;
static final int    DOWNLOAD_BUF_SIZE = 4 * 1024;

//----------------------------------------------------------------------------
/** 根据网址下载 HTML 字串 */
String download(final String url, final String charset) throws IOException {
	if (url == null || url.length() <= 0) {
		return "";
	}
	StringBuilder html = new StringBuilder();
	try (InputStreamReader reader = new InputStreamReader(new URL(url).openStream(), charset)) {
		char[] buffer = new char[DOWNLOAD_BUF_SIZE];
		for (int n = reader.read(buffer) ; n >= 0 ; n = reader.read(buffer)) {
			html.append(buffer, 0, n);
		}
	}
	return html.toString();
}

//----------------------------------------------------------------------------
/** 截取前缀、后缀中间内容返回类型 */
static class MidContent {
	/** 截取前缀、后缀中间内容 */
	public String content;
	/** 原始字串下标 */
	public int    index;
	/** 构造函数 */
	public MidContent(final String content, final int index) {
		this.content = content;
		this.index = index;
	}
}

static final MidContent NOT_FOUND = new MidContent("", -1);

//----------------------------------------------------------------------------
/** 从指定下标开始查找前缀，再截取前缀、后缀中间内容。 */
MidContent mid(final String source, final int start, final String prefix, final String postfix) {
	if (source == null || start < 0 || prefix == null || postfix == null) {
		return NOT_FOUND;
	}
	int i = source.indexOf(prefix, start);
	if (i < 0) {
		return NOT_FOUND;
	}
	i += prefix.length();
	int i2 = source.indexOf(postfix, i);
	if (i2 < 0) {
		return NOT_FOUND;
	}
	return new MidContent(source.substring(i, i2), i);
}

//----------------------------------------------------------------------------
/** 先查找 find，再从找到位置查找前缀，截取前缀、后缀中间内容。 */
MidContent mid(final String source, final int start, final String find, final String prefix, final String postfix) {
	if (source == null || start < 0 || find == null) {
		return NOT_FOUND;
	}
	int i = source.indexOf(find, start);
	if (i < 0) {
		return NOT_FOUND;
	}
	i += find.length();
	return mid(source, i, prefix, postfix);	
}
%>
<%
//----------------------------------------------------------------------------
// 呈现数据
Map<String, Object> model = new HashMap<>();

//----------------------------------------------------------------------------
try {
	// 读气象局预报网页 HTML
	String html = download(SRC_URL, SRC_CHARSET);
	MidContent m;
	
	// 未来24小时天气预报
	m = mid(html, 0, "未来24小时天气预报", "<img src=\"../..", "\"");
	model.put("未来24小时图标1", m.content);
	m = mid(html, m.index, "<img src=\"../..", "\""); // 箭头
	m = mid(html, m.index, "<img src=\"../..", "\"");
	model.put("未来24小时图标2", m.content);
	m = mid(html, m.index, "今天白天到夜间：", "</td>");
	model.put("今天白天到夜间", m.content);
	m = mid(html, m.index, "气　　温：", "<td width=\"215\">", "</td>");
	model.put("气温", m.content);
	m = mid(html, m.index, "相对湿度：", "<td>", "</td>");
	model.put("相对湿度", m.content);
	m = mid(html, m.index, "风向级别：", "<td>", "</td>");
	model.put("风向级别", m.content);
	m = mid(html, m.index, "发布时间：", "</td>");
	model.put("发布时间", m.content);
	
	// 天气趋势预报
	m = mid(html, m.index, "天气趋势预报", "text-indent:24px;\">", "</td>");
	model.put("天气趋势预报", m.content);
	
	// 七日天气预报
	m.index = html.indexOf("七日天气预报", m.index);
	for (int i = 1 ; i <= FORECAST_DAYS ; i++) {
		String pre = "一日预报" + i;
		m = mid(html, m.index, "<td height=\"25\" colspan=\"2\" align=\"center\">", "</td>");
		model.put(pre + "日期", m.content);
		m = mid(html, m.index, "<img src=\"", "\"");
		model.put(pre + "图标1", m.content);
		m = mid(html, m.index, "<img src=\"", "\"");
		model.put(pre + "图标2", m.content);
		m = mid(html, m.index, "气温<br />", "</td>");
		model.put(pre + "气温", m.content);
	}
	
} catch (Exception e) {
	String echo = String.format("从气象局下载预报出错：[%s]%s", e.getClass().getName(), e.getLocalizedMessage());
	out.println(echo);
}
%>
<!DOCTYPE html>
<html>
<head>
<title>南海气象局预报</title>
<base href="http://www.nh121.cn/"/>
<meta name="viewport" content="width=device-width, initial-scale=1"/>
<style>
	body { margin: 1ex; font-size: 16px; color: #666; }
	h1 { background: #3E98C5; color: white; line-height: 150%; padding-left: 1ex; font-size: 1em; font-weight: normal; }
	strong, th { color: #1E90FF; }
	.未来24小时 img { width: 48px; height: 48px; }
	.未来24小时 th { white-space: nowrap; }
	.一日预报 { float: left; text-align: center; border: solid 1px #CCC; padding: 1ex; margin-right: 1ex; margin-bottom: 1ex; }
	.一日预报 img { width: 32px; height: 32px; }
	.一日预报完 { clear: both; }
</style>
</head>

<body>
<!-- 未来24小时天气预报 -->
<h1>未来24小时天气预报</h1>
<table class="未来24小时">
<tr>
	<td rowspan="5">
		<img src="<%=model.get("未来24小时图标1")%>"/>
		<br/>
		<img src="<%=model.get("未来24小时图标2")%>"/>
	</td>
	<th>今天白天　<br/>　到夜间：</th>
	<td><%=model.get("今天白天到夜间")%></td>
</tr>
<tr>
	<th>气　　温：</th>
	<td><%=model.get("气温")%></td>
</tr>
<tr>
	<th>相对湿度：</th>
	<td><%=model.get("相对湿度")%></td>
</tr>
<tr>
	<th>风向级别：</th>
	<td><%=model.get("风向级别")%></td>
</tr>
<tr>
	<th>发布时间：</th>
	<td><%=model.get("发布时间")%></td>
</tr>
</table>

<!-- 天气趋势预报 -->
<h1>天气趋势预报</h1>
<p>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<%=model.get("天气趋势预报")%></p>

<!-- 七日天气预报 -->
<h1>七日天气预报</h1>
<%
for (int i = 1 ; i <= FORECAST_DAYS ; i++) {
	String pre = "一日预报" + i;
%>
<div class="一日预报">
	<strong><%=model.get(pre + "日期")%></strong><br/>
	<%=model.get(pre + "气温")%><br/>
	<img src="<%=model.get(pre + "图标1")%>"/>
	&nbsp;
	<img src="<%=model.get(pre + "图标2")%>"/>
</div>
<% } // for FORECAST_DAYS %>
<div class="一日预报完"></div>

</body>
</html>
