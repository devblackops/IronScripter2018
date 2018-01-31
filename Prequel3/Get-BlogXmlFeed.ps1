function Get-BlogXmlFeed {
    <#
    .SYNOPSIS
    Returns posts from the PowerShell.org (or other blog) XML feed.
    .DESCRIPTION
    Returns posts from the PowerShell.org (or other blog) XML feed and optionally opens the post link in the browser or displays the raw HTML.
    .PARAMETER Uri
    The XML feed URI to retrieve.
    .PARAMETER OpenIn
    Open post link in the operating systems' default browser or display the raw HTML.
    .PARAMETER Index
    One or more index numbers of post to retrieve.
    .EXAMPLE
    C:\> Get-BlogXmlFeed
    Returns the latest posts in the PowerShell.org XML feed.
    .EXAMPLE
    C:\> Get-BlogXmlFeed -Index 0
    Return the first post from the XML feed.
    .EXAMPLE
    C:\> Get-BlogXmlFeed -Index 0, 1 -OpenIn Browser
    Return the first two posts from the XML deed and open in the browser.
    .EXAMPLE
    C:\> Get-BlogXmlFeed -OpenIn Console
    Get all posts from the XML feed and display the raw HTML text of the post links.
    .LINK
    http://ironscripter.us/
    #>
    [OutputType('Blog.Post')]
    [CmdletBinding()]
    param(
        [string]$Uri = 'https://powershell.org/feed/',

        [ValidateSet('Browser', 'Console')]
        [string]$OpenIn,

        [ValidateNotNull()]
        [int[]]$Index = @()
    )

    # Get XML feed and extract relevant properties
    $feed = [xml](Invoke-WebRequest -Uri $Uri -UseBasicParsing)
    $itemIndex = 0
    $posts = $feed.rss.channel.item | ForEach-Object {
        [pscustomobject]@{
            PSTypeName      = 'Blog.Post'
            Index           = $null
            Title           = $_.title
            PublicationDate = [datetime]$_.pubDate
            Link            = $_.link
            Author          = $_.creator.InnerText
        }
    } | Sort-Object -Property PublicationDate -Descending | ForEach-Object {
        $_.'Index' = $itemIndex++
        $_
    }

    # Filter posts by index
    if ($Index.Count -gt 0) {
        $posts = $posts | Where-Object {$_.Index -in $Index}
    }

    # Return post(s) or optionally open link(s) in browser/console
    foreach($post in $posts) {
        switch ($OpenIn) {
            'Browser' { Start-Process $post.Link }
            'Console' { (Invoke-WebRequest -Uri $post.Link).Content }
            default   { $post }
        }
    }
}
