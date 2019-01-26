//Mapbox Studio Public Access tokens:

//infowetrust
//mapboxgl.accessToken = 'pk.eyJ1IjoicmphbmRyZXdzIiwiYSI6ImNpeW5wMWUzbjAwMW8zM3BucWVremoxNjQifQ.NdFCDsj_fjlIzfTUh8JmoQ';

//startupcarto
mapboxgl.accessToken =
  'pk.eyJ1Ijoic3RhcnR1cGNhcnRvIiwiYSI6ImNqN204cHllbDE1c3czNGxhdndpcGI5NjMifQ.zUztT384kQartYPh21LWxQ'

// Set bounds to USA (with a big buffer)
var bounds = [
  [-175, 0], // Southwest coordinates X,Y
  [-35, 70] // Northeast coordinates X,Y
]
var centerPoint = [-101, 33]

//Load a new map in the 'map' HTML div
var map = new mapboxgl.Map({
  container: 'map',
  //custom style id for style that removes black dots for city centers

  //infowetrust
  //style: 'mapbox://styles/rjandrews/cj1z8se9i00122rqznzg893co',

  //startupcarto
  style: 'mapbox://styles/startupcarto/cj7mb40yp96l52rnvh1e3b6j2',
  attributionControl: false,
  hash: true,
  center: centerPoint,
  zoom: 3.65,
  minZoom: 3,
  maxZoom: 15,
  maxBounds: bounds // Sets var bounds as max
})

//define quality (state & city & address) colors
var colorList = [
  [0, '#FBF2CD'],
  [1, '#FBF2CD'],
  [501, '#F3BF83'],
  [751, '#E97262'],
  [901, '#CF2870'],
  [951, '#9F26A6'],
  [981, '#5A3BC4'],
  [991, '#452D95']
]

//sets all circle strokes to Black
var strokeBlack = [[0, 'rgba(0,0,0,0)'], [1, '#000'], [999, '#000']]

/*
    // Old context color scheme: Blue Green Yellow
    var colorBuckets = [
      "rgba(0,0,0,0)",
      '#0C64A5',
      '#5BB9CD',
      '#8ED2BE',
      '#BEE6C0',
      '#DCF1D7'
    ]
    */

// New Diverging color scheme: Blue White Green
var colorBuckets = [
  'rgba(0,0,0,0)',
  '#0C64A5',
  '#A0CFD9',
  '#DFEFE7',
  '#A8E2AB',
  '#50B899'
]

//define REAI (county) colors
var colorReai = [
  [0, colorBuckets[0]],
  [1, colorBuckets[1]],
  [25, colorBuckets[2]],
  [50, colorBuckets[3]],
  [75, colorBuckets[4]],
  [100, colorBuckets[5]]
]

//define Census colors
var colorCensus = [
  [0, colorBuckets[0]],
  [1, colorBuckets[1]],
  [201, colorBuckets[2]],
  [401, colorBuckets[3]],
  [601, colorBuckets[4]],
  [801, colorBuckets[5]]
]

//tileset variables

map.on('load', function() {
  var Year = 2005 //global so radio button can use it

  //Tilesets from Mapbox

  //composite data: {{state,}} county, city, address
  map.addSource('composite_data', {
    //name
    type: 'vector',
    //infowetrust
    //url: 'mapbox://rjandrews.6yqumwnl,rjandrews.dru9lbxc,rjandrews.6204a9mh,rjandrews.d5u6km4c'
    //startupcarto TK add STATE!
    url:
      'mapbox://startupcarto.d6ocer6d,startupcarto.8r1dzrwh,startupcarto.4rhl0dub,startupcarto.6o9q2fch' //update these
  })

  //Add STATE BUBBLES
  map.addLayer(
    {
      id: 'stateCircle',
      type: 'circle',
      source: 'composite_data',
      'source-layer': 'allstates_state-6k4mkj',
      //Add data-driven styles for circle-color
      paint: {
        'circle-color': {
          property: 'qy' + Year, //the prefix qy has been changed from original qp
          type: 'interval',
          default: 'rgba(0,0,0,0)',
          stops: colorList
        },

        'circle-radius': [
          //Adds data-driven styles for circle radius
          'interpolate',
          ['linear'],
          ['zoom'],
          2,
          ['+', ['/', ['number', ['get', 'o' + Year]], 20000], 10],
          4,
          ['+', ['/', ['number', ['get', 'o' + Year]], 10000], 10]
        ],

        'circle-opacity': [
          //creates smooth transition when zooming
          'interpolate',
          ['linear'],
          ['zoom'],
          3.6,
          ['number', 0.9],
          3.7,
          ['number', 0.0]
        ],

        'circle-stroke-width': 1, //circle-stroke creates border

        'circle-stroke-color': {
          property: 'qy' + Year,
          type: 'interval',
          default: 'rgba(0,0,0,0)',
          stops: strokeBlack
        },

        'circle-stroke-opacity': [
          'interpolate',
          ['linear'],
          ['zoom'],
          3.6,
          ['number', 0.15], //[zoom level, opacity]
          3.7,
          ['number', 0.0]
        ]
      }
      //filter: ['==', 'year', Year]
    },
    'waterway-label'
  )

  // COUNTY SHADING (1st because it is bottom layer)
  map.addLayer(
    {
      id: 'Shading',
      type: 'fill',
      source: 'composite_data', //name of tileset
      'source-layer': '2000census2-ast166', //name of layer
      layout: {
        visibility: 'none' //allows visible-none of layer
      },
      paint: {
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
          stops: [[0, 0.5]]
        }
      }
    },
    'waterway-label'
  )

  // CITY BUBBLES
  map.addLayer(
    {
      id: 'cityCircle',
      type: 'circle',
      source: 'composite_data',
      'source-layer': 'allstates_citiesgeojson',
      paint: {
        //Add data-driven styles for circle-color
        'circle-color': {
          property: 'qy' + Year,
          type: 'interval',
          default: 'rgba(0,0,0,0)',
          stops: colorList
        },
        //Adds data-driven styles for circle radius
        'circle-radius': [
          'interpolate',
          ['linear'],
          ['zoom'],
          3,
          ['+', ['/', ['number', ['get', 'o' + Year]], 8000], 2],
          11,
          ['+', ['/', ['number', ['get', 'o' + Year]], 500], 2]
        ],
        //creates smooth transition when zooming
        'circle-opacity': [
          'interpolate',
          ['linear'],
          ['zoom'],
          3.6,
          ['number', 0.0],
          3.7,
          ['number', 0.9],
          10,
          ['number', 0.9],
          10.1,
          ['number', 0.0]
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
          'interpolate',
          ['linear'],
          ['zoom'],
          3.6,
          ['number', 0.0],
          3.7,
          ['number', 0.15],
          10,
          ['number', 0.15],
          10.1,
          ['number', 0.0]
        ]
      }
      //filter: ['==', 'year', Year]
    },
    'waterway-label'
  )

  // ADDRESS BUBBLES
  map.addLayer(
    {
      id: 'addressCircle',
      type: 'circle',
      source: 'composite_data',
      'source-layer': 'allstates_addressgeojson',

      paint: {
        //Add data-driven styles for circle-color
        'circle-color': {
          property: 'qy' + Year,
          type: 'interval',
          default: 'rgba(0,0,0,0)',
          stops: colorList
        },
        //Adds data-driven styles for circle radius
        'circle-radius': [
          'interpolate',
          ['linear'],
          ['zoom'],
          9,
          ['+', ['/', ['number', ['get', 'o' + Year]], 3], 3],
          15,
          ['+', ['/', ['number', ['get', 'o' + Year]], 2], 3]
        ],

        'circle-opacity': [
          'interpolate',
          ['linear'],
          ['zoom'],
          10,
          ['number', 0.0],
          10.1,
          ['number', 0.9]
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
          'interpolate',
          ['linear'],
          ['zoom'],
          10,
          ['number', 0.0],
          10.1,
          ['number', 0.15]
        ]
      }
      //filter: ['==', 'Year', Year]
    },
    'waterway-label'
  )

  //listens for radio selection changes
  $(document).ready(function() {
    $('input[type=radio]').click(function() {
      console.log(this.value)
      var shadingID = $('input[name="shading"]:checked').val()
      console.log('shadingID', shadingID)

      if (shadingID == 'population') {
        map
          .setPaintProperty('Shading', 'fill-color', {
            property: 'PopPerc',
            type: 'interval',
            //default: 'black',
            default: 'rgba(0,0,0,0)',
            stops: colorCensus
          })
          .setLayoutProperty('Shading', 'visibility', 'visible')
      } else if (shadingID == 'income') {
        map
          .setPaintProperty('Shading', 'fill-color', {
            property: 'IncomePerc',
            type: 'interval',
            default: 'rgba(0,0,0,0)',
            stops: colorCensus
          })
          .setLayoutProperty('Shading', 'visibility', 'visible')
      } else if (shadingID == 'reai') {
        map
          .setPaintProperty('Shading', 'fill-color', {
            property: 'reai_' + Year,
            type: 'interval',
            default: 'rgba(0,0,0,0)',
            stops: colorReai
          })
          .setLayoutProperty('Shading', 'visibility', 'visible')
      } else {
        map.setLayoutProperty('Shading', 'visibility', 'none')
      }
    })
  })

  //change console text color with zoom level
  var zoomThresholdLow = 3.65
  var zoomThresholdHigh = 10.05

  map.on('zoom', function() {
    if (map.getZoom() > zoomThresholdHigh) {
      stateLabel.className = 'gray-label'
      cityLabel.className = 'gray-label'
      addressLabel.className = 'blue-label'
    } else if (map.getZoom() < zoomThresholdLow) {
      stateLabel.className = 'blue-label'
      cityLabel.className = 'gray-label'
      addressLabel.className = 'gray-label'
    } else {
      stateLabel.className = 'gray-label'
      cityLabel.className = 'blue-label'
      addressLabel.className = 'gray-label'
    }
  })

  //get the current year as an integer
  document.getElementById('slider').addEventListener('change', function(e) {
    Year = parseInt(e.target.value)

    //use current year
    document.getElementById('Year').innerText = Year
    //TK add state updates here
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
      'interpolate',
      ['linear'],
      ['zoom'],
      2,
      ['+', ['/', ['number', ['get', 'o' + Year]], 20000], 10],
      4,
      ['+', ['/', ['number', ['get', 'o' + Year]], 10000], 10]
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

    map.setPaintProperty('cityCircle', 'circle-radius', [
      'interpolate',
      ['linear'],
      ['zoom'],
      3,
      ['+', ['/', ['number', ['get', 'o' + Year]], 8000], 2],
      11,
      ['+', ['/', ['number', ['get', 'o' + Year]], 500], 2]
    ])
    //address updates
    map.setPaintProperty('addressCircle', 'circle-color', {
      property: 'qy' + Year,
      type: 'interval',
      default: 'rgba(0,0,0,0)',
      stops: colorList
    })

    map.setPaintProperty('addressCircle', 'circle-radius', [
      'interpolate',
      ['linear'],
      ['zoom'],
      9,
      ['+', ['/', ['number', ['get', 'o' + Year]], 3], 3],
      15,
      ['+', ['/', ['number', ['get', 'o' + Year]], 2], 3]
    ])

    map.setPaintProperty('addressCircle', 'circle-stroke-color', {
      property: 'qy' + Year,
      type: 'interval',
      default: 'rgba(0,0,0,0)',
      stops: strokeBlack
    })
    //Shading
    var shadingID = $('input[name="shading"]:checked').val()
    console.log('check shading in yr function:', shadingID)

    if (shadingID == 'reai') {
      map.setPaintProperty('Shading', 'fill-color', {
        property: 'reai_' + Year,
        type: 'interval',
        stops: colorReai
      })
    }
  })

  //TOOLTIPS: TK add zoom layering filtering + city names

  // When a click event occurs near a place, open a popup tooltip at the
  // location of the feature, with description HTML from its properties.

  map.on('click', function(e) {
    var features = map.queryRenderedFeatures(e.point, {
      layers: ['cityCircle']
    })

    if (!features.length) {
      return
    }

    var feature = features[0]

    var popup = new mapboxgl.Popup()
      .setLngLat(feature.geometry.coordinates)
      .setHTML(
        '<div id="popup" class="popup" style="z-index: 10;"> ' +
          '<ul class="list-group">' +
          '<li class="list-group-item"> City: ' +
          feature.properties['city'] +
          ' </li>' +
          '<li class="list-group-item"> State: ' +
          feature.properties['state'] +
          ' </li>' +
          '<li class="list-group-item"> Quality %: ' +
          feature.properties['qy' + Year] / 10 +
          '<li class="list-group-item"> Quantity %: ' +
          feature.properties['o' + Year] / 10 +
          '<li class="list-group-item"> Year: ' +
          [Year] +
          '</ul> </div>'
      )
      .addTo(map)
  })

  // Use the same approach as above to indicate that the symbols are clickable
  // by changing the cursor style to 'pointer'.
  map.on('mousemove', function(e) {
    var features = map.queryRenderedFeatures(e.point, {
      layers: ['cityCircle']
    })
    map.getCanvas().style.cursor = features.length ? 'pointer' : ''
  })
})

// ADD things
//search bar
map.addControl(
  new MapboxGeocoder({
    accessToken: mapboxgl.accessToken
  })
)

//search bar custom position
//var geocoder = new MapboxGeocoder({
//  accessToken: mapboxgl.accessToken
//});

//document.getElementById('geocoder').appendChild(geocoder.onAdd(map));

//zoom and rotation controls to the map.
map.addControl(
  new mapboxgl.NavigationControl({
    position: 'top-right'
  })
)

//HIDE THINGS

// disable map rotation using right click + drag
map.dragRotate.disable()
// disable map rotation using touch rotation gesture
map.touchZoomRotate.disableRotation()

//hides Alaska beyond specified zoom level
//map.on('zoomend', function () {
//if (map.getZoom() > 3.75) {
//document.getElementById('minimap1').style.visibility = 'hidden'
// } else {
//   document.getElementById('minimap1').style.visibility = 'visible'
// }    });
