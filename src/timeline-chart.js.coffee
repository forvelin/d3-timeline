// d3-timeline in CoffeeScript
// Forked from https://github.com/jiahuang/d3-timeline
// The MIT License (MIT)
// Copyright (c) 2015 - Jia Huang

// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

// The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

'use strict';


var colors = ['#8dd3c7','#ffffb3','#bebada','#fb8072','#80b1d3','#fdb462','#b3de69','#fccde5','#d9d9d9','#bc80bd','#ccebc5','#ffed6f']

function _classCallCheck(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError("Cannot call a class as a function"); } }
var _createClass = function () { function defineProperties(target, props) { for (var i = 0; i < props.length; i++) { var descriptor = props[i]; descriptor.enumerable = descriptor.enumerable || false; descriptor.configurable = true; if ("value" in descriptor) descriptor.writable = true; Object.defineProperty(target, descriptor.key, descriptor); } } return function (Constructor, protoProps, staticProps) { if (protoProps) defineProperties(Constructor.prototype, protoProps); if (staticProps) defineProperties(Constructor, staticProps); return Constructor; }; }();


var TimelineChart = function () {


    function TimelineChart(element, data, opts) {
        _classCallCheck(this, TimelineChart);

        var self = this;

        element.classList.add('timeline-chart');

        var options = this.extendOptions(opts);

        var allElements = data.reduce(function (agg, e) {
            return agg.concat(e.data);
        }, []);

        var minDt = d3.min(allElements, this.getPointMinDt);
        var maxDt = d3.max(allElements, this.getPointMaxDt);

        maxDt = new Date(maxDt.getTime() + (maxDt.getTime() - minDt.getTime())*0.1);
        minDt = new Date(minDt.getTime() - (maxDt.getTime() - minDt.getTime())*0.1);

        var domain = [minDt, maxDt];
        if(options.domain) domain = options.domain;

        var elementWidth = options.width || element.clientWidth;
        var elementHeight = options.height || element.clientHeight;

        var margin = {
            top: 0,
            right: 0,
            bottom: 20,
            left: 0
        };

        var width = elementWidth - margin.left - margin.right;
        var height = elementHeight - margin.top - margin.bottom;

        var groupWidth = 100;

        var x = d3.time.scale().domain(domain).range([groupWidth, width]);

        var xAxis = d3.svg.axis().scale(x).orient('bottom').tickSize(-height);

        var zoom = d3.behavior.zoom().x(x).on('zoom', zoomed);

        this.zoom2 = zoom;

        var svg = d3.select(element).append('svg').attr('width', width + margin.left + margin.right).attr('height', height + margin.top + margin.bottom).append('g').attr('transform', 'translate(' + margin.left + ',' + margin.top + ')').call(zoom);

        svg.append('defs').append('clipPath').attr('id', 'chart-content').append('rect').attr('x', groupWidth).attr('y', 0).attr('height', height).attr('width', width - groupWidth);

        svg.append('rect').attr('class', 'chart-bounds').attr('x', groupWidth).attr('y', 0).attr('height', height).attr('width', width - groupWidth);

        svg.append('g').attr('class', 'x axis').attr('transform', 'translate(0,' + height + ')').call(xAxis);

        var groupHeight = height / data.length;
        var groupSection = svg.selectAll('.group-section').data(data).enter().append('line').attr('class', 'group-section').attr('x1', 0).attr('x2', width).attr('y1', function (d, i) {
            return groupHeight * (i + 1);
        }).attr('y2', function (d, i) {
            return groupHeight * (i + 1);
        });

        var groupLabels = svg.selectAll('.group-label').data(data).enter().append('text').attr('class', 'group-label').attr('x', 0).attr('y', function (d, i) {
            return groupHeight * i + groupHeight / 2 + 5.5;
        }).attr('dx', '0.5em').text(function (d) {
            return d.label;
        });

        var lineSection = svg.append('line').attr('x1', groupWidth).attr('x2', groupWidth).attr('y1', 0).attr('y2', height).attr('stroke', 'black');

        var groupIntervalItems = svg.selectAll('.group-interval-item').data(data).enter().append('g').attr('clip-path', 'url(#chart-content)').attr('class', 'item').attr('transform', function (d, i) {
            return 'translate(0, ' + groupHeight * i + ')';
        }).selectAll('.dot').data(function (d) {
            return d.data.filter(function (_) {
                return _.type === TimelineChart.TYPE.INTERVAL;
            });
        }).enter();

        var intervalBarHeight = 0.8 * groupHeight;
        var intervalBarMargin = (groupHeight - intervalBarHeight) / 2;
        var intervals = groupIntervalItems.append('rect').attr('class', 'interval').attr('width', function (d) {
            return x(d.to) - x(d.from);
        }).attr('height', intervalBarHeight).attr('y', intervalBarMargin).attr('x', function (d) {
            return x(d.from);
        });

        var intervalTexts = groupIntervalItems.append('text').text(function (d) {
            return d.label;
        }).attr('fill', 'white').attr('class', 'interval-text').attr('y', groupHeight / 2 + 5).attr('x', function (d) {
            return x(d.from);
        });

        var groupDotItems = svg.selectAll('.group-dot-item').data(data).enter().append('g').attr('clip-path', 'url(#chart-content)').attr('class', 'item').attr('transform', function (d, i) {
            return 'translate(0, ' + groupHeight * i + ')';
        }).selectAll('.dot').data(function (d) {
            return d.data.filter(function (_) {
                return _.type === TimelineChart.TYPE.POINT;
            });
        }).enter();

        var dots = groupDotItems.append('circle').attr('class', 'dot').attr('cx', function (d) {
            return x(d.at);
        }).attr('cy', groupHeight / 2).attr('r', 5);

        if (options.tip) {
            if (d3.tip) {
                var tip = d3.tip().attr('class', 'd3-tip').html(options.tip);
                svg.call(tip);
                dots.on('mouseover', tip.show).on('mouseout', tip.hide);
                intervals.on('mouseover', tip.show).on('mouseout', tip.hide);
            } else {
                console.error('Please make sure you have d3.tip included as dependency (https://github.com/Caged/d3-tip)');
            }
        }

        zoomed();

        function zoomed() {
            if (self.onVizChangeFn && d3.event) {
                self.onVizChangeFn.call(self, {
                    scale: d3.event.scale,
                    translate: d3.event.translate,
                    domain: x.domain()
                });
            }

            svg.select('.x.axis').call(xAxis);

            svg.selectAll('circle.dot').attr('cx', function (d) {
                return x(d.at);
            });
            svg.selectAll('rect.interval').attr('x', function (d) {
                return x(d.from);
            }).style('fill', function(d) {var color = d3.scale.category20b(); return colors[d.task_id%12]; }) .attr('width', function (d) {
                return x(d.to) - x(d.from);
            });

            svg.selectAll('.interval-text').attr('x', function (d) {
                var positionData = getTextPositionData.call(this, d);
                if (positionData.upToPosition - groupWidth - 10 < positionData.textWidth) {
                    return positionData.upToPosition;
                } else if (positionData.xPosition < groupWidth && positionData.upToPosition > groupWidth) {
                    return groupWidth;
                }
                return positionData.xPosition;
            }).attr('text-anchor', function (d) {
                var positionData = getTextPositionData.call(this, d);
                if (positionData.upToPosition - groupWidth - 10 < positionData.textWidth) {
                    return 'end';
                }
                return 'start';
            }).attr('dx', function (d) {
                var positionData = getTextPositionData.call(this, d);
                if (positionData.upToPosition - groupWidth - 10 < positionData.textWidth) {
                    return '-0.5em';
                }
                return '0.5em';
            }).text(function (d) {
                var positionData = getTextPositionData.call(this, d);
                var percent = (positionData.width - options.textTruncateThreshold) / positionData.textWidth;
                if (percent < 1) {
                    if (positionData.width > options.textTruncateThreshold) {

                        d.label = d.label.toString();
                        return d.label.substr(0, Math.floor(d.label.length * percent)) + '...';
                    } else {
                        return '';
                    }
                }

                return d.label;
            });

            function getTextPositionData(d) {
                this.textSizeInPx = this.textSizeInPx || this.getComputedTextLength();
                var from = x(d.from);
                var to = x(d.to);
                return {
                    xPosition: from,
                    upToPosition: to,
                    width: to - from,
                    textWidth: this.textSizeInPx
                };
            }
        }
    }


    _createClass(TimelineChart, [{
        key: 'extendOptions',
        value: function extendOptions() {
            var ext = arguments.length <= 0 || arguments[0] === undefined ? {} : arguments[0];

            var defaultOptions = {
                tip: undefined,
                textTruncateThreshold: 30
            };
            Object.keys(ext).map(function (k) {
                return defaultOptions[k] = ext[k];
            });
            return defaultOptions;
        }
    }, {
        key: 'getPointMinDt',
        value: function getPointMinDt(p) {
            return p.type === TimelineChart.TYPE.POINT ? p.at : p.from;
        }
    }, {
        key: 'getPointMaxDt',
        value: function getPointMaxDt(p) {
            return p.type === TimelineChart.TYPE.POINT ? p.at : p.to;
        }
    }, {
        key: 'onVizChange',
        value: function onVizChange(fn) {
            this.onVizChangeFn = fn;
            return this;
        }
    }]);

    return TimelineChart;
}();

TimelineChart.TYPE = {
    POINT: Symbol(),
    INTERVAL: Symbol()
};
//# sourceMappingURL=timeline-chart.js.map
