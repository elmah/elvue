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

$ ?= ->
    if typeof it is \string then document.querySelector it else it
    |> angular.element

formatSimpleErrorTypeName = (name) ->
    m = name.match /^([a-z0-9]+\.)+?([a-z0-9]*exception)$/i
    switch
    | not m? => name
    | _ =>
        last = m.pop!
        last.slice 0, -'exception'.length or last

app = angular
    .module \app, <[ angularMoment ]>
    .constant \angularMomentConfig, preprocess: \utc

app.directive \googleChart, ->
    # Inspiration: http://gavindraper.com/2013/07/30/google-charts-in-angularjs/
    restrict : \A
    link: ($scope, $elem, $attr) ->
        ngModel = $scope[$attr.ngModel]
        return unless ngModel?
        options = {}
        options.title = ngModel.title if ngModel.title
        chart = new google.visualization[$attr.googleChart] $elem[0]
        ngModel.dataTable |> chart.draw _, options
        $scope.$watch "#{$attr.ngModel}", _, true <| ->
            chart.draw ngModel.dataTable, ngModel.config

app.directive \elmahDownload, ->
    restrict : \A
    link: ($scope, $elem, $attr) !->
        let src = $scope.src, id = $scope.$id
            return unless src?
            callback = \onerrors + id
            "=parent.#{encodeURIComponent(callback)}"
            |> src.replace (/=CALLBACK(&|$)/), _
            |> $ $elem .attr 'src', _
            window[callback] ?= (data) !-> $scope.$apply !-> $scope.onerrors? data

app.controller \page, new Array \$scope, \config, ($scope, config) ->

    dt = new google.visualization.DataTable!
        ..addColumn \string, \Error
        ..addColumn \number, \Count

    $scope.gc =
        dataTable: dt
        config:
            is3D  : true
            width : 500
            height: 333
            chartArea: left: 10, top: 10, width: '90%', height: '90%'

    $scope.src = # JSONP-ish request
        let src = config.src || 'elmah.axd/download', limit = +config.limit
            "#{src}?format=html-jsonp&callback=CALLBACK" \
            + if limit > 0 then "&limit=#{limit}" else ''

    $scope
        ..callbackCount = 0
        ..loadedCount = 0
        ..totalCount = 0
        ..errors = errors = []
        ..byType = byType = {}
        ..sort = (key) !->
            if key is @sortKey
                @sortDescending = not @sortDescending
            else
                @sortKey = key
                @sortDescending = key isnt \type
        ..sort \count

    label = do (labeling = config.labeling) ->
        | typeof labeling is \function => labeling
        | labeling is \words => (type) -> $.trim type.replace /([a-z])([A-Z])/g, '$1 $2' .toLowerCase!
        | _ => id

    $scope.onerrors = (data) !->

        $scope.callbackCount++
        $scope.totalCount = data.total
        $scope.loadedCount += data.errors.length

        for err in data.errors # Group each error by its type

            type = err.type |> formatSimpleErrorTypeName |> label _, err

            if not (entry = byType[type])?

                errors.push entry = byType[type] =
                    type : type
                    type$: err.type
                    count: 0
                    i    : errors.length
                    time : new Date Date.parse err.time
                    time$: err.time.replace /\.\d{1,3}Z$/, 'Z' # remove seconds fraction
                    href : [h for h in err.hrefs when h?.href? and h.type is 'text/html'].0?.href

                dt.addRows 1
                dt.setValue entry.i, 0, type

            dt.setValue entry.i, 1, ++entry.count

google.setOnLoadCallback \
    do (config = @config ? {}) -> !->

    # Document title

    if config.title
        document.title = config.title
    else
        location = window.location
        if location.protocol in <[ http: https: ]>
            document.title += " for \u201c#{location.hostname}\u201d"
    $ \h1 .text document.title

    # Boot Angular

    app.value \config, config
    angular.bootstrap document.body, <[ app ]>

google.load \visualization, \1, packages: <[ corechart ]>
