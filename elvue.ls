/*
 * ELVUE - Reports for ELMAH Error Logs
 * Copyright (c) 2011 Atif Aziz. All rights reserved.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

id = -> it

Number::formatInt ?= switch
| Number::formatMoney? => do (f = (.formatMoney 0)) -> -> f @
| otherwise => -> @toString!

formatSimpleErrorTypeName = (name) ->
    m = name.match /^([a-z0-9]+\.)+?([a-z0-9]*exception)$/i
    switch
    | not m? => name
    | otherwise =>
        last = m.pop!
        last.slice 0, -'exception'.length or last

google.load \visualization, \1, packages: <[ corechart ]>

google.setOnLoadCallback \
    do (global = @,
        config = @config ? {},
        vis    = document.getElementById \visualization,
        iframe = document.getElementById \elf) -> !->

    # Create and populate the data table.

    dt = new google.visualization.DataTable!
        ..addColumn \string, \Error
        ..addColumn \number, \Count

    # Create and draw the visualization.

    chart = new google.visualization.PieChart vis

    # Document title

    if config.title
        document.title = config.title
    else
        location = window.location
        if location.protocol in <[ http: https: ]>
            document.title += " for \u201c#{location.hostname}\u201d"
    $ \h1 .text <| document.title

    # JSONP request

    src = do (src = config.src or 'elmah.axd/download') ->
        "#{src}?format=html-jsonp&callback=parent.onerrors"
    limit = +config.limit
    if limit > 0 then src += "&limit=#{limit}"
    iframe.src = src

    # JSONP callback

    loadedCount = 0
    byType = {}

    global.onerrors ?= (data) !->

        loadedCount += data.errors.length

        $ 'table#errors caption' .text do
            if loadedCount < data.total
                "#{loadedCount.formatInt!} of #{data.total.formatInt!} errors"
            else
                "#{data.total.formatInt!} errors"

        errors = $ '#errors'

        label = do (labeling = config.labeling) ->
            switch
            | typeof labeling is \function => labeling
            | labeling is \words => (type) -> $.trim type.replace /([a-z])([A-Z])/g, '$1 $2' .toLowerCase!
            | otherwise id

        for err in $ data.errors

            # Group each error by its type

            type = err.type |> formatSimpleErrorTypeName  |> label _, err
            entry = byType[type] or count: 0, i: 0, e: null
            entry.count += 1

            if entry.e?
                entry.count.formatInt! |> entry.e.text
            else
                entry.i = dt.getNumberOfRows!
                dt.addRows 1
                dt.setValue entry.i, 0, type
                tr = $ \<tr>
                td = $ \<td> .appendTo tr
                $ \<abbr> .attr \title, err.type
                          .text type
                          .appendTo td
                parent = td = $ \<td> .appendTo tr
                hrefs = $.grep err.hrefs, (e) -> e and e.type is 'text/html'
                if hrefs.length
                    parent = a = $ '<a target="_blank">' .attr 'href', hrefs[0].href
                                                         .appendTo td
                $ \<abbr> .addClass \timeago
                          .attr \title, err.time.replace /\.\d{1,3}Z$/, 'Z'
                          .text '' + new Date Date.parse err.time
                          .appendTo parent
                entry.e = $ \<td> .addClass 'num '
                                  .text entry.count.formatInt!
                                  .appendTo tr
                tr.appendTo errors
                byType[type] = entry

            row = entry.e.closest \tr

            # Re-sort rows

            while true
                prev = row.prev!.children 'td:last-child' .text! .replace ',', '' |> parseInt
                if isNaN prev or entry.count <= prev then break
                row.prev!.before row

            while true
                row = entry.e.closest \tr
                next = row.next!.children 'td:last-child' .text! .replace ',', '' |> parseInt
                if isNaN next or entry.count >= next then break
                row.next!.after row

            dt.setValue entry.i, 1, entry.count

        $ \.timeago .timeago!

        chart.draw dt,
            is3D  : true
            width : 500
            height: 333
            chartArea: left:10, top:10, width:'90%', height:'90%'
