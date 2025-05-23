# Script for generating the plots for blog-birthday-1 post

using Dates
using YAML
using WordCloud
using Images
using CairoMakie
using CairoMakie: Axis
using HTTP
using EzXML
using ProgressMeter

# Intentionally structured as a script rather than a library with 
# a user-friendly main entrypoint. Need to make changes for your site? 
# Alter the script directly! :D 

#####
##### Some helper functions! For data munging
#####

function fetch_data(item)
    response = HTTP.get(item.link)
    return String(response.body)
end

function default_date_conversion(date_str::String)
    str = date_str[1:end-4] # Chop off time zone 
    return Date(str, dateformat"eee, dd uu yyyy HH:MM:SS")
end

function process_item(item;
    html_preprocess=(html::String) -> html,
    date_process=default_date_conversion)
    # Get contents of post 
    raw_html = fetch_data(item)
    html = html_preprocess(raw_html)
    contents = html2text(html)

    # Metadata used later (doesn't need to happen here, but whatevs)
    date = date_process(item.pubDate)
    return (; contents, date)
end

function default_html_preprocess(html)
    lines = split(html, "\n")

    # remove header and footer
    # very brittle, designed around specific site (hannahilea.com) entries 
    # so content *starts* after the </h1> entry (i.e., just after the title)
    i = findfirst(contains("</h1>"), lines)
    lines = lines[(i+2):end]

    # ...and ends just before some constant footer content
    i = findlast(contains("<ul class=\"date\">"), lines)
    lines = lines[1:(i-1)]

    # Reformat it back similar to the input
    c = join(lines, " ")
    c = replace(c, "\n" => " ")
    return c
end


#####
##### Helper functions for plotting!
#####

function wordcloud_from_post(words, output_filepath)
    wc = paintcloud(words;
        mask=shape(box, 500, 400; cornerradius=2),
        masksize=:original,
        colors=["#000080"],
        backgroundcolor="linen",
        angles=(0, 45, 90),
        fonts=["Tahoma"],
        density=0.7,
        maxnum=500)
    mkpath(dirname(output_filepath))
    save(output_filepath, wc)
    return wc
end

#####
##### Script entrypoint
#####

url = Base.prompt("Enter the url for your RSS feed"; default="https://hannahilea.com/rss")

@info "Fetching and parsing `$url`..."
xml_doc = let
    response = HTTP.get(url)
    content = String(response.body)
    xml = parsexml(content)
    root(xml)
end

@info "Pulling blog details out of rss feed xml"
items = map(findall("//item", xml_doc)) do item
    # Convert xml item to list of NamedTuples per item
    return NamedTuple(map(elements(item)) do element
        return (Symbol(element.name), element.content)
    end)
end

@info "...and validating entries"
for (i, item) in enumerate(items)
    haskey(item, :pubDate) || @warn "No `pubDate` found for item $i; will likely fail downstream steps. Fix or remove item."
    haskey(item, :link) || @warn "No `link` found for item $i; will likely fail downstream steps. Fix or remove item."
end

@info "Fetching blog content..."
fetched_items = @showprogress desc = "" map(items) do item
    return process_item(item;
        html_preprocess=identity,
        date_process=default_date_conversion)
end

@info "Plot time!"
output_dir = Base.prompt("Where do you want output images saved?"; default=joinpath(".", "viz-output-$(now())"))

@info "Generating per-post word clouds..."
@showprogress for (i, item) in enumerate(sort(fetched_items; by=x -> x.date))
    wordcloud_from_post(item.contents, joinpath(output_dir, "wc-$i.png"))
end

@info "Make all-post word cloud..."
all_words = join([item.contents for item in fetched_items], " ")
wordcloud_from_post(all_words, joinpath(output_dir, "wc-all.png"))


@info "Make post timeline plot..."

function make_timeline_plot(dates, values, output_filepath;
    title="",
    ylabel="Word count",
    figsize=(800, 300))

    # okay this is dumb, but it seems like makie and date-based axes don't play 
    # nice? so do the dumb thing---i.e., manually index the dates
    min_day, max_day = extrema(dates)
    first_month_day = floor(min_day, Month(1))
    last_month_day = ceil(max_day, Month(1))
    daily = collect(first_month_day:Day(1):last_month_day)
    xs = [findfirst(==(d), daily) for d in dates]

    # Prepare x-axis labels
    monthly_dates = first_month_day:Month(1):last_month_day
    monthly_ticks = [findfirst(==(m), daily) for m in monthly_dates]
    monthly_labels = map(enumerate(monthly_dates)) do (i, d)
        m = monthabbr(d)
        if m == "Jan" || i == 1
            str = "$(year(d)) $m"
            return "'" * str[3:end]
        end
        return m
    end

    ytickformat = (values) -> begin
        map(values) do value
            value == 0 && return "0"
            # This is dumb but I'm sick of fighting it
            value % 1000 == 0 && return "$(Int(value/1000))k"
            return "$(value/1000)k"
        end
    end

    f = Figure(; size=figsize)
    ax = Axis(f[1, 1];
        title, ylabel,
        xlabel="Publication date",
        ytickformat,
        xticks=(monthly_ticks, monthly_labels),
        xticklabelrotation=0.3)
    barplot!(ax, xs, values;
        strokewidth=0.5,
        strokecolor=:white,
        width=3,
        color="#000080",)
    save(output_filepath, f)
    return f
end

per_post_dates = [f.date for f in fetched_items]
per_post_counts = [length(f.contents) for f in fetched_items]

make_timeline_plot(per_post_dates, per_post_counts,
    joinpath(output_dir, "timeline.png"))
