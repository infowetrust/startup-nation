//Mapbox Studio Public Access tokens:

//startupcarto
mapboxgl.accessToken =
  'pk.eyJ1Ijoic3RhcnR1cGNhcnRvIiwiYSI6ImNqN204cHllbDE1c3czNGxhdndpcGI5NjMifQ.zUztT384kQartYPh21LWxQ';

// Set bounds to USA (with a big buffer)
var bounds = [
  [-100, 30], // Southwest coordinates X,Y
  [-75, 45] // Northeast coordinates X,Y
];
var centerPoint = [-87.2, 37.5]

//Load a new map in the 'map' HTML div
var map = new mapboxgl.Map({
  container: 'map',
  
  //startupcarto
  //state fills created using tutorial https://docs.mapbox.com/help/tutorials/style-single-country/
  //with data from http://www.naturalearthdata.com/downloads/10m-cultural-vectors/

  style: 'mapbox://styles/startupcarto/cjwe5cbat1ibh1cp9zu9a8ed9',
  attributionControl: false,
  hash: true, //populates URL with zoom level and coordinates of current view
  center: centerPoint,
  zoom: 7,
  minZoom: 3,
  maxZoom: 15,
  maxBounds: bounds // Sets var bounds as max

});

//define colors for quality
var colorList = [
  [0, "rgba(0,0,0,0)"],
  [1, '#FBF2CD'],
  [501, '#F3BF83'],
  [951, '#74add1'],
  [981, '#2F6BC7']

/*mayor's conference colors
[0, "rgba(0,0,0,0)"],
  [1, '#FBF2CD'],
  [501, '#F3BF83'],
  [751, '#E97262'],
  [901, '#CF2870'],
  [951, '#9F26A6'],
  [981, '#5A3BC4'],
  [991, '#452D95']*/
];

//sets all circle strokes to BLACK
var strokeBlack = [
  [0, "rgba(0,0,0,0)"],
  [1, '#000'],
  [999, '#000']
];

//Context colors diverge: Green White Purple
var colorBuckets = [
  "rgba(0,0,0,0)",
  '#5aae61',
  '#d9f0d3',
  '#f7f7f7',
  '#e7d4e8',
  '#9970ab',
]

//define REAI (county) colors
var colorReai = [
  [0, colorBuckets[0]],
  [1, colorBuckets[1]],
  [25, colorBuckets[2]],
  [50, colorBuckets[3]],
  [75, colorBuckets[4]],
  [100, colorBuckets[5]]
];

//define Census colors
var colorCensus = [
  [0, colorBuckets[0]],
  [1, colorBuckets[1]],
  [201, colorBuckets[2]],
  [401, colorBuckets[3]],
  [601, colorBuckets[4]],
  [801, colorBuckets[5]]
];

//tileset variables

map.on('load', function () {

  var Year = 2014; //global so radio button can use it

  //Tilesets from Mapbox

  //composite data: (state), city, address, county
  //tileset keys from startupcarto's Mapbox account
  map.addSource('composite_data', {
    type: 'vector',

  url: 'mapbox://startupcarto.da0q2w15,startupcarto.5vb8100j,startupcarto.8r1dzrwh'
  });

  // COUNTY SHADING (1st because it is bottom layer)
  map.addLayer({
    'id': 'Shading',
    'type': 'fill',
    'source': 'composite_data', //name of tileset
    'source-layer': '2000census2-ast166', //name of layer
    'layout': {
      'visibility': 'none' //allows visible-none of layer
    },
    'paint': {
      'fill-color': {
        property: 'reai_' + Year,
        type: 'interval',
        default: 'rgba(0,0,0,0)',
        stops: colorReai
      },
      'fill-opacity': {
        property: 'reai_' + Year,
        type: 'interval',
        default: 0.5,
        stops: [
          [0, 0.5]
        ]
      },
    }
  }, 'waterway-label');

  // STATE BUBBLES
  /*
  map.addLayer({
    'id': 'stateCircle',
    'type': 'circle',
    'source': 'composite_data',
    'source-layer': 'usa_state',
    'symbol-z-layer': 'source',
    'paint': {
      //Add data-driven styles for circle-color
      'circle-color': {
        property: 'qy' + Year,
        type: 'interval',
        default: 'rgba(0,0,0,0)',
        stops: colorList
      },
      //Adds data-driven styles for circle size
      'circle-radius': [
        // 'zoom level', obs value / divisor + floor_#
        'interpolate', ['linear'], ['zoom'],
        3, [ '+', ['/', ['number', ['get','o' + Year]], 10000], 1.5],
        3.5, [ '+', ['/', ['number', ['get','o' + Year]], 10000], 2]
      ],
      //quickly transition between state and city layers
      'circle-opacity': [
        'interpolate', ['linear'], ['zoom'],
        3.45, ['number', 1.0],
        3.5, ['number', 0.0],
      ],
      //circle-stroke creates border
      'circle-stroke-width': 1,

      'circle-stroke-color': {
        property: 'qy' + Year,
        type: 'interval',
        default: 'rgba(0,0,0,0)',
        stops: strokeBlack
      },

      'circle-stroke-opacity': [
        'interpolate', ['linear'], ['zoom'],
        3.45, ['number', 0.15],
        3.5, ['number', 0.0],
      ],
    },
    //filter: ['==', 'year', Year]
  }, 'waterway-label');
  */
  
  // CITY BUBBLES
  map.addLayer({
    'id': 'cityCircle',
    'type': 'circle',
    'source': 'composite_data',
    'source-layer': 'ky_city',
    'symbol-z-layer': 'source',
    'paint': {
      //Add data-driven styles for circle-color
      'circle-color': {
        property: 'qy' + Year,
        type: 'interval',
        default: 'rgba(0,0,0,0)',
        stops: colorList
      },
      //Adds data-driven styles for circle size
      'circle-radius': [
        'interpolate', ['linear'], ['zoom'],
        6, [ '+', ['/', ['number', ['get','so' + Year]], 8], 1.5],
        8, [ '+', ['/', ['number', ['get','so' + Year]], 4], 2],
        10, [ '+', ['/', ['number', ['get','so' + Year]], 1.5], 2]
        // zoom level, obs value / divisor + floor_#
        // Original Kentucky values are:
        // 6, [ '+', ['/', ['number', ['get','so' + Year]], 5], 2],
        // 10, [ '+', ['/', ['number', ['get','so' + Year]], 0.5], 2]
      ],
      //quickly transition between city and address layers
      'circle-opacity': [
        'interpolate', ['linear'], ['zoom'],
        3.45, ['number', 0.0],
        3.5, ['number', 1.0],
        10, ['number', 1.0],
        10.1, ['number', 0.0],
      ],
      //circle-stroke creates border
      'circle-stroke-width': 1,

      'circle-stroke-color': {
        property: 'qy' + Year,
        type: 'interval',
        default: 'rgba(0,0,0,0)',
        stops: strokeBlack
      },

      'circle-stroke-opacity': [
        'interpolate', ['linear'], ['zoom'],
        3.45, ['number', 0.0],
        3.5, ['number', 0.15],
        10, ['number', 0.15],
        10.1, ['number', 0.0],
      ],
    },
    //filter: ['==', 'year', Year]
  }, 'waterway-label');

  // ADDRESS BUBBLES
  map.addLayer({
    'id': 'addressCircle',
    'type': 'circle',
    'source': 'composite_data',
    'source-layer': 'ky_address',

    'paint': {
      //Add data-driven styles for circle-color
      'circle-color': {
        property: 'qy' + Year,
        type: 'interval',
        default: 'rgba(0,0,0,0)',
        stops: colorList
      },
      //Adds data-driven styles for circle size
      'circle-radius': [
        'interpolate', ['linear'], ['zoom'],
        10, [ '+', ['/', ['number', ['get','o' + Year]], 3], 3],
        15, [ '+', ['/', ['number', ['get','o' + Year]], 2], 3]
      ],

      'circle-opacity': [
        'interpolate', ['linear'], ['zoom'],
        10, ['number', 0.0],
        10.1, ['number', 1.0]
      ],

      //circle-stroke creates border
      'circle-stroke-width': 1,

      'circle-stroke-color': {
        property: 'qy' + Year,
        type: 'interval',
        default: 'rgba(0,0,0,0)',
        stops: strokeBlack
      },

      'circle-stroke-opacity': [
        'interpolate', ['linear'], ['zoom'],
        10, ['number', 0.0],
        10.1, ['number', 0.15]
      ],
    },
    //filter: ['==', 'Year', Year]
  }, 'waterway-label')

  //listens for radio selection changes
  $(document).ready(function () {
    $('input[type=radio]').click(function () {
      console.log(this.value);
      var shadingID = $('input[name="shading"]:checked').val();
      console.log('shadingID', shadingID);

      if (shadingID == 'population') {
        map.setPaintProperty('Shading', 'fill-color', {
          property: 'PopPerc',
          type: 'interval',
          //default: 'black',
          default: 'rgba(0,0,0,0)',
          stops: colorCensus
        }).setLayoutProperty('Shading', 'visibility', 'visible')
      } else if (shadingID == 'income') {
        map.setPaintProperty('Shading', 'fill-color', {
          property: 'IncomePerc',
          type: 'interval',
          default: 'rgba(0,0,0,0)',
          stops: colorCensus
        }).setLayoutProperty('Shading', 'visibility', 'visible')
      } else if (shadingID == 'reai') {
        map.setPaintProperty('Shading', 'fill-color', {
          property: 'reai_' + Year,
          type: 'interval',
          default: 'rgba(0,0,0,0)',
          stops: colorReai
        }).setLayoutProperty('Shading', 'visibility', 'visible')
      } else {
        map.setLayoutProperty('Shading', 'visibility', 'none')
      }
    });
  });

  //change console text color with zoom level in middle of transition
  var zoomThreshold1 = 3.47;
  var zoomThreshold2 = 10.05;

  map.on('zoom', function() {
    if (map.getZoom() > zoomThreshold2) {
        stateLabel.className = 'gray-label';
        cityLabel.className = 'gray-label';
        addressLabel.className = 'blue-label';
    } else if (map.getZoom() < zoomThreshold1) {
        stateLabel.className = 'blue-label';
        cityLabel.className = 'gray-label';
        addressLabel.className = 'gray-label';
    } else {
        stateLabel.className = 'gray-label';
        cityLabel.className = 'blue-label';
        addressLabel.className = 'gray-label';
    }
  });

  //get the current year as an integer
  document.getElementById('slider').addEventListener('change', function (e) {
    Year = parseInt(e.target.value);

    //use current year
    document.getElementById('Year').innerText = Year;

    //state updates
    map.setPaintProperty('stateCircle', 'circle-color', {
      property: 'qy' + Year,
      type: 'interval',
      default: 'rgba(0,0,0,0)',
      stops: colorList
    })

    map.setPaintProperty('stateCircle', 'circle-stroke-color', {
      property: 'qy' + Year,
      type: 'interval',
      default: 'rgba(0,0,0,0)',
      stops: strokeBlack
    })

    map.setPaintProperty('stateCircle', 'circle-radius', [
      'interpolate', ['linear'], ['zoom'],
      3, [ '+', ['/', ['number', ['get','o' + Year]], 5000], 3],
      3.5, [ '+', ['/', ['number', ['get','o' + Year]], 5000], 3]
    ])

    //city updates
    map.setPaintProperty('cityCircle', 'circle-color', {
      property: 'qy' + Year,
      type: 'interval',
      default: 'rgba(0,0,0,0)',
      stops: colorList
    })

    map.setPaintProperty('cityCircle', 'circle-stroke-color', {
      property: 'qy' + Year,
      type: 'interval',
      default: 'rgba(0,0,0,0)',
      stops: strokeBlack
    })

    //"so" is square root of "o" (raw count)
    //Mapbox "expressions" tutorial: https://docs.mapbox.com/help/tutorials/mapbox-gl-js-expressions/
    map.setPaintProperty('cityCircle', 'circle-radius', [
      'interpolate', ['linear'], ['zoom'],
      6, [ '+', ['/', ['number', ['get','so' + Year]], 5], 2],
      10, [ '+', ['/', ['number', ['get','so' + Year]], 0.5], 2]
    ])

    //address updates
    map.setPaintProperty('addressCircle', 'circle-color', {
      property: 'qy' + Year,
      type: 'interval',
      default: 'rgba(0,0,0,0)',
      stops: colorList
    })

    map.setPaintProperty('addressCircle', 'circle-radius', [
      'interpolate', ['linear'], ['zoom'],
      10, [ '+', ['/', ['number', ['get','o' + Year]], 3], 3],
      15, [ '+', ['/', ['number', ['get','o' + Year]], 2], 3]
    ])

    map.setPaintProperty('addressCircle', 'circle-stroke-color', {
      property: 'qy' + Year,
      type: 'interval',
      default: 'rgba(0,0,0,0)',
      stops: strokeBlack
    })

    //Shading
    var shadingID = $('input[name="shading"]:checked').val();
    console.log("check shading in yr function:", shadingID);

    if (shadingID == 'reai') {
      map.setPaintProperty('Shading', 'fill-color', {
        property: 'reai_' + Year,
        type: 'interval',
        stops: colorReai
      })
    }
  });

  //TOOLTIPS: TK add zoom layering filtering
  // When a click event occurs near a place, open a popup tooltip at the
  // location of the feature, with description HTML from its properties.
  
  map.on('click', function (e) {
    if (map.getZoom() > zoomThreshold1 && map.getZoom() < zoomThreshold2) {
      var features = map.queryRenderedFeatures(e.point, {
        layers: ['cityCircle']
      });
    } else if (map.getZoom() < zoomThreshold1) {
      var features = map.queryRenderedFeatures(e.point, {
        layers: ['stateCircle']
      });
    }

    if (!features.length) {
      return;
    }

    var feature = features[0];

    if (map.getZoom() > zoomThreshold1 && map.getZoom() < zoomThreshold2) {
      var popup = new mapboxgl.Popup()
      .setLngLat(feature.geometry.coordinates)
      .setHTML('<div id="popup" class="popup" style="z-index: 10;"> ' +
          '<ul class="list-group">' +
          '<li class="list-group-item"> City: ' + feature.properties['city'] + " </li>" +
          '<li class="list-group-item"> Quality %: ' + Math.round(feature.properties['qy' + Year]/10) +
          '<li class="list-group-item"> Quantity: ' + feature.properties['o' + Year] +
          '<li class="list-group-item"> Year: ' + [Year] +
          '</ul> </div>')
          .addTo(map);
      } else if (map.getZoom() < zoomThreshold1) {
        var popup = new mapboxgl.Popup()
        .setLngLat(feature.geometry.coordinates)
        .setHTML('<div id="popup" class="popup" style="z-index: 10;"> ' +
          '<ul class="list-group">' +
          '<li class="list-group-item"> State: ' + feature.properties['datastate'] + " </li>" +
          '<li class="list-group-item"> Quality %: ' + Math.round(feature.properties['qy' + Year]/10) +
          '<li class="list-group-item"> Quantity: ' + feature.properties['o' + Year] +
          '<li class="list-group-item"> Year: ' + [Year] +
          '</ul> </div>')
          .addTo(map);
      }
  });

  // Use the same approach as above to indicate that the symbols are clickable
  // by changing the cursor style to 'pointer'.
  map.on('mousemove', function (e) {
    if (map.getZoom() > zoomThreshold1 && map.getZoom() < zoomThreshold2) {
      var features = map.queryRenderedFeatures(e.point, {
        layers: ['cityCircle']
      });
      map.getCanvas().style.cursor = (features.length) ? 'pointer' : '';
    } else if (map.getZoom() < zoomThreshold1) {
      var features = map.queryRenderedFeatures(e.point, {
        layers: ['stateCircle']
      });
      map.getCanvas().style.cursor = (features.length) ? 'pointer' : '';
    }
  });

});

// ADD things
//search bar
map.addControl(new MapboxGeocoder({
  accessToken: mapboxgl.accessToken
}));

//search bar custom position
//var geocoder = new MapboxGeocoder({
//  accessToken: mapboxgl.accessToken
//});

//document.getElementById('geocoder').appendChild(geocoder.onAdd(map));

//zoom and rotation controls to the map.
map.addControl(new mapboxgl.NavigationControl({
  'position': 'top-right'
}));

//HIDE THINGS

// disable map rotation using right click + drag
map.dragRotate.disable();
// disable map rotation using touch rotation gesture
map.touchZoomRotate.disableRotation();
