//Mapbox Studio Public Access tokens:

//startupcarto
mapboxgl.accessToken =
  'pk.eyJ1Ijoic3RhcnR1cGNhcnRvIiwiYSI6ImNqN204cHllbDE1c3czNGxhdndpcGI5NjMifQ.zUztT384kQartYPh21LWxQ';

// Set bounds to USA (with a big buffer)
var bounds = [
  [-175, 0], // Southwest coordinates X,Y
  [-35, 70] // Northeast coordinates X,Y
];
var centerPoint = [-105, 38]

//Load a new map in the 'map' HTML div
var map = new mapboxgl.Map({
  container: 'map',
  
  //startupcarto
  //state fills created using tutorial https://docs.mapbox.com/help/tutorials/style-single-country/
  //with data from http://www.naturalearthdata.com/downloads/10m-cultural-vectors/

  style: 'mapbox://styles/startupcarto/cjv8kuz6675w21ft6k8zc1j5r',
  attributionControl: false,
  hash: true, //populates URL with zoom level and coordinates of current view
  center: centerPoint,
  zoom: 3.5,
  minZoom: 3,
  maxZoom: 15,
  maxBounds: bounds // Sets var bounds as max

});

//define zoom transitions between all layers
//crossFade is the transition zone between layers
var crossFade = 0.05;

//bottom of each layer's range
var zoomList = [
  3, // state (minZoom)
  3.5, // metro
  7, // city
  10, // city treering
  12, // address
  15 // maxZoom
]

//transition zones between layers
var zoomArray = [
  [zoomList[0], zoomList[1] - crossFade], // state
  [zoomList[1], zoomList[2] - crossFade], // metro
  [zoomList[2], zoomList[3] - crossFade], // city
  [zoomList[3], zoomList[4] - crossFade], // city treering
  [zoomList[4], zoomList[5] - crossFade] // address
];

//bubble size denominators (bigger number = smaller bubble)
var bubbleSize = [
[5000, 5000], // state
[20,3], // metro
[2,1], // city
[1,1], // city treering
[3,2] // address
];

//define colors for quality
var colorList = [
  [0, "rgba(0,0,0,0)"],
  [1, '#FBF2CD'],
  [560, '#F3BF83'],
  [978, '#74add1'],
  [997, '#2F6BC7'],
  [1000, '#003EAD']
];

//sets all circle strokes to BLACK
var strokeBlack = [
  [0, "rgba(0,0,0,0)"],
  [1, '#000'],
  [999, '#000']
];

// New context colors diverge: Green White Purple
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

  //composite data
  //tileset keys from startupcarto's Mapbox account
  map.addSource('composite_data', {
    type: 'vector',
  //order: state, metro, city, address, county
  url: 'mapbox://startupcarto.1p59ecdn,startupcarto.cv03ptb5,startupcarto.d1ax561g,startupcarto.5ofy8j8s,startupcarto.8r1dzrwh'
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
  }, 'place-neighbourhood');

  // STATE BUBBLES
  map.addLayer({
    'id': 'stateCircle',
    'type': 'circle',
    'source': 'composite_data',
    'source-layer': 'usa_state',
    'symbol-z-layer': 'source',
    'paint': {
      //Add data-driven styles for circle-color
      'circle-color': {
        property: 'qg' + Year,
        type: 'interval',
        default: 'rgba(0,0,0,0)',
        stops: colorList
      },
      //Adds data-driven styles for circle size
      'circle-radius': [
        // Mapbox "expressions" tutorial: https://docs.mapbox.com/help/tutorials/mapbox-gl-js-expressions/
        // 'zoom level', obs value / divisor + floor_#
        'interpolate', ['linear'], ['zoom'],
        zoomArray[0][0], [ '+', ['/', ['number', ['get','o' + Year]], bubbleSize[0][0]], 0],
        zoomArray[0][1], [ '+', ['/', ['number', ['get','o' + Year]], bubbleSize[0][1]], 0]
      ],
      //quickly transition between state and city layers
      'circle-opacity': [
        'interpolate', ['linear'], ['zoom'],
        zoomArray[0][1], ['number', 1.0],
        zoomArray[1][0], ['number', 0.0],
      ],
      //circle-stroke creates border
      'circle-stroke-width': 1,

      'circle-stroke-color': {
        property: 'qg' + Year,
        type: 'interval',
        default: 'rgba(0,0,0,0)',
        stops: strokeBlack
      },

      'circle-stroke-opacity': [
        'interpolate', ['linear'], ['zoom'],
        zoomArray[0][1], ['number', 0.15],
        zoomArray[1][0], ['number', 0.0],
      ],
    },
    //filter: ['==', 'year', Year]
  }, 'place-neighbourhood');

  // metro BUBBLES
  map.addLayer({
    'id': 'metroCircle',
    'type': 'circle',
    'source': 'composite_data',
    'source-layer': 'usa_msa',
    'symbol-z-layer': 'source',
    'paint': {
      //Add data-driven styles for circle-color
      'circle-color': {
        property: 'qg' + Year,
        type: 'interval',
        default: 'rgba(0,0,0,0)',
        stops: colorList
      },
      //Adds data-driven styles for circle size
      'circle-radius': [
        'interpolate', ['linear'], ['zoom'],
        // zoom level, obs value / divisor + floor_#        
        zoomArray[1][0], [ '+', ['/', ['number', ['get','so' + Year]], bubbleSize[1][0]], 0],
        zoomArray[1][1], [ '+', ['/', ['number', ['get','so' + Year]], bubbleSize[1][1]], 0]
      ],
      //quickly transition between layers
      'circle-opacity': [
        'interpolate', ['linear'], ['zoom'],
        zoomArray[0][1], ['number', 0.0],
        zoomArray[1][0], ['number', 1.0],
        zoomArray[1][1], ['number', 1.0],
        zoomArray[2][0], ['number', 0.0],
      ],
      //circle-stroke creates border
      'circle-stroke-width': 1,

      'circle-stroke-color': {
        property: 'qg' + Year,
        type: 'interval',
        default: 'rgba(0,0,0,0)',
        stops: strokeBlack
      },

      'circle-stroke-opacity': [
        'interpolate', ['linear'], ['zoom'],
        zoomArray[0][1], ['number', 0.0],
        zoomArray[1][0], ['number', 0.15],
        zoomArray[1][1], ['number', 0.15],
        zoomArray[2][0], ['number', 0.0],
      ],
    },
    //filter: ['==', 'year', Year]
  }, 'place-neighbourhood');
  
  // CITY BUBBLES
  map.addLayer({
    'id': 'cityCircle',
    'type': 'circle',
    'source': 'composite_data',
    'source-layer': 'usa_city',
    'symbol-z-layer': 'source',
    'paint': {
      //Add data-driven styles for circle-color
      'circle-color': {
        property: 'qg' + Year,
        type: 'interval',
        default: 'rgba(0,0,0,0)',
        stops: colorList
      },
      //Adds data-driven styles for circle size
      'circle-radius': [
        'interpolate', ['linear'], ['zoom'],
        // zoom level, obs value / divisor + floor_#        
        zoomArray[2][0], [ '+', ['/', ['number', ['get','so' + Year]], bubbleSize[2][0]], 0],
        zoomArray[2][1], [ '+', ['/', ['number', ['get','so' + Year]], bubbleSize[2][1]], 0]
      ],
      //quickly transition between layers
      'circle-opacity': [
        'interpolate', ['linear'], ['zoom'],
        zoomArray[1][1], ['number', 0.0],
        zoomArray[2][0], ['number', 1.0],
        zoomArray[2][1], ['number', 1.0],
        zoomArray[3][0], ['number', 0.0],
      ],
      //circle-stroke creates border
      'circle-stroke-width': 1,

      'circle-stroke-color': {
        property: 'qg' + Year,
        type: 'interval',
        default: 'rgba(0,0,0,0)',
        stops: strokeBlack
      },

      'circle-stroke-opacity': [
        'interpolate', ['linear'], ['zoom'],
        zoomArray[1][1], ['number', 0.0],
        zoomArray[2][0], ['number', 0.15],
        zoomArray[2][1], ['number', 0.15],
        zoomArray[3][0], ['number', 0.0],
      ],
    },
    //filter: ['==', 'year', Year]
  }, 'place-neighbourhood'); //'place-neighbourhood'

  // CITY TREERINGS
  // CITY LLC
  map.addLayer({
    'id': 'llcCircle',
    'type': 'circle',
    'source': 'composite_data',
    'source-layer': 'usa_city',
    'symbol-z-layer': 'source',
    'paint': {
      //Add data-driven styles for circle-color
      'circle-color': {
        property: 'qg' + Year,
        type: 'interval',
        default: 'rgba(0,0,0,0)',
        stops: [
          [0, "rgba(0,0,0,0)"],
          [1, colorList[1][1]]
        ],
      },
      //Adds data-driven styles for circle size
      'circle-radius': [
        'interpolate', ['linear'], ['zoom'],
        // zoom level, obs value / divisor + floor_#        
        zoomArray[3][0], [ '+', ['/', ['number', ['get','so' + Year]], bubbleSize[3][0]], 0],
        zoomArray[3][1], [ '+', ['/', ['number', ['get','so' + Year]], bubbleSize[3][1]], 0]
      ],
      //quickly transition between layers
      'circle-opacity': [
        'interpolate', ['linear'], ['zoom'],
        zoomArray[2][1], ['number', 0.0],
        zoomArray[3][0], ['number', 1.0],
        zoomArray[3][1], ['number', 1.0],
        zoomArray[4][0], ['number', 0.0],
      ],
      //circle-stroke creates border
      'circle-stroke-width': 1,

      'circle-stroke-color': {
        property: 'qg' + Year,
        type: 'interval',
        default: 'rgba(0,0,0,0)',
        stops: strokeBlack
      },

      'circle-stroke-opacity': [
        'interpolate', ['linear'], ['zoom'],
        zoomArray[2][1], ['number', 0.0],
        zoomArray[3][0], ['number', 0.15],
        zoomArray[3][1], ['number', 0.15],
        zoomArray[4][0], ['number', 0.0],
      ],
    },
    //filter: ['==', 'year', Year]
  }, 'place-neighbourhood'); //waterway-label

  // CITY CORP
  map.addLayer({
    'id': 'corpCircle',
    'type': 'circle',
    'source': 'composite_data',
    'source-layer': 'usa_city',
    'symbol-z-layer': 'source',
    'paint': {
      //Add data-driven styles for circle-color
      'circle-color': {
        property: 'qg' + Year,
        type: 'interval',
        default: 'rgba(0,0,0,0)',
        stops: [
          [0, "rgba(0,0,0,0)"],
          [1, colorList[2][1]]
        ],
      },
      //Adds data-driven styles for circle size
      'circle-radius': [
        'interpolate', ['linear'], ['zoom'],
        // zoom level, obs value / divisor + floor_#        
        zoomArray[3][0], [ '+', ['/', ['number', ['get','TCORP' + Year]], bubbleSize[3][0]], 0],
        zoomArray[3][1], [ '+', ['/', ['number', ['get','TCORP' + Year]], bubbleSize[3][1]], 0]
      ],
      //quickly transition between layers
      'circle-opacity': [
        'interpolate', ['linear'], ['zoom'],
        zoomArray[2][1], ['number', 0.0],
        zoomArray[3][0], ['number', 1.0],
        zoomArray[3][1], ['number', 1.0],
        zoomArray[4][0], ['number', 0.0],
      ],
      //circle-stroke creates border
      'circle-stroke-width': 0,
      'circle-stroke-opacity': 0,
    },
  }, 'place-neighbourhood');

  // CITY DELAWARE
  map.addLayer({
    'id': 'deCircle',
    'type': 'circle',
    'source': 'composite_data',
    'source-layer': 'usa_city',
    'symbol-z-layer': 'source',
    'paint': {
      //Add data-driven styles for circle-color
      'circle-color': {
        property: 'qg' + Year,
        type: 'interval',
        default: 'rgba(0,0,0,0)',
        stops: [
          [0, "rgba(0,0,0,0)"],
          [1, colorList[3][1]]
        ],
      },
      //Adds data-driven styles for circle size
      'circle-radius': [
        'interpolate', ['linear'], ['zoom'],
        // zoom level, obs value / divisor + floor_#        
        zoomArray[3][0], [ '+', ['/', ['number', ['get','TDE' + Year]], bubbleSize[3][0]], 0],
        zoomArray[3][1], [ '+', ['/', ['number', ['get','TDE' + Year]], bubbleSize[3][1]], 0]
      ],
      //quickly transition between layers
      'circle-opacity': [
        'interpolate', ['linear'], ['zoom'],
        zoomArray[2][1], ['number', 0.0],
        zoomArray[3][0], ['number', 1.0],
        zoomArray[3][1], ['number', 1.0],
        zoomArray[4][0], ['number', 0.0],
      ],
      //circle-stroke creates border
      'circle-stroke-width': 0,
      'circle-stroke-opacity': 0,
    },
  }, 'place-neighbourhood');

  // CITY PATENT OR TRADEMARK
  map.addLayer({
    'id': 'pttmCircle',
    'type': 'circle',
    'source': 'composite_data',
    'source-layer': 'usa_city',
    'symbol-z-layer': 'source',
    'paint': {
      //Add data-driven styles for circle-color
      'circle-color': {
        property: 'qg' + Year,
        type: 'interval',
        default: 'rgba(0,0,0,0)',
        stops: [
          [0, "rgba(0,0,0,0)"],
          [1, colorList[4][1]]
        ],
      },
      //Adds data-driven styles for circle size
      'circle-radius': [
        'interpolate', ['linear'], ['zoom'],
        // zoom level, obs value / divisor + floor_#        
        zoomArray[3][0], [ '+', ['/', ['number', ['get','TPTTM' + Year]], bubbleSize[3][0]], 0],
        zoomArray[3][1], [ '+', ['/', ['number', ['get','TPTTM' + Year]], bubbleSize[3][1]], 0]
      ],
      //quickly transition between layers
      'circle-opacity': [
        'interpolate', ['linear'], ['zoom'],
        zoomArray[2][1], ['number', 0.0],
        zoomArray[3][0], ['number', 1.0],
        zoomArray[3][1], ['number', 1.0],
        zoomArray[4][0], ['number', 0.0],
      ],
      //circle-stroke creates border
      'circle-stroke-width': 0,
      'circle-stroke-opacity': 0,
    },
  }, 'place-neighbourhood');

  // CITY TWO+ MEASURES
  map.addLayer({
    'id': 'twoupCircle',
    'type': 'circle',
    'source': 'composite_data',
    'source-layer': 'usa_city',
    'symbol-z-layer': 'source',
    'paint': {
      //Add data-driven styles for circle-color
      'circle-color': {
        property: 'qg' + Year,
        type: 'interval',
        default: 'rgba(0,0,0,0)',
        stops: [
          [0, "rgba(0,0,0,0)"],
          [1, colorList[5][1]]
        ],
      },
      //Adds data-driven styles for circle size
      'circle-radius': [
        'interpolate', ['linear'], ['zoom'],
        // zoom level, obs value / divisor + floor_#        
        zoomArray[3][0], [ '+', ['/', ['number', ['get','TTWOUP' + Year]], bubbleSize[3][0]], 0],
        zoomArray[3][1], [ '+', ['/', ['number', ['get','TTWOUP' + Year]], bubbleSize[3][1]], 0]
      ],
      //quickly transition between layers
      'circle-opacity': [
        'interpolate', ['linear'], ['zoom'],
        zoomArray[2][1], ['number', 0.0],
        zoomArray[3][0], ['number', 1.0],
        zoomArray[3][1], ['number', 1.0],
        zoomArray[4][0], ['number', 0.0],
      ],
      //circle-stroke creates border
      'circle-stroke-width': 0,
      'circle-stroke-opacity': 0,
    },
  }, 'place-neighbourhood');

  // ADDRESS BUBBLES
  map.addLayer({
    'id': 'addressCircle',
    'type': 'circle',
    'source': 'composite_data',
    'source-layer': 'usa_address',

    'paint': {
      //Add data-driven styles for circle-color
      'circle-color': {
        property: 'qg' + Year,
        type: 'interval',
        default: 'rgba(0,0,0,0)',
        stops: colorList
      },
      //Adds data-driven styles for circle size
      //floor included so addresses with only 1 biz can be seen
      'circle-radius': [
        'interpolate', ['linear'], ['zoom'],
        zoomArray[4][0], [ '+', ['/', ['number', ['get','o' + Year]], bubbleSize[4][0]], 2],
        zoomArray[4][1], [ '+', ['/', ['number', ['get','o' + Year]], bubbleSize[4][1]], 2]
      ],

      'circle-opacity': [
        'interpolate', ['linear'], ['zoom'],
        zoomArray[3][1], ['number', 0.0],
        zoomArray[4][0], ['number', 1.0]
      ],

      //circle-stroke creates border
      'circle-stroke-width': 1,

      'circle-stroke-color': {
        property: 'qg' + Year,
        type: 'interval',
        default: 'rgba(0,0,0,0)',
        stops: strokeBlack
      },

      'circle-stroke-opacity': [
        'interpolate', ['linear'], ['zoom'],
        zoomArray[3][1], ['number', 0.0],
        zoomArray[4][0], ['number', 0.15]
      ],
    },
    //filter: ['==', 'Year', Year]
  }, 'place-neighbourhood')

  //listens for CONTEXT radio selection changes
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

  //change console text color with zoom level
  map.on('zoom', function() {
    if (map.getZoom() >= zoomList[4]) { //shades address
        stateLabel.className = 'grey-label';
        metroLabel.className = 'grey-label';
        cityLabel.className = 'grey-label';
        addressLabel.className = 'blue-label';
    } else if (map.getZoom() >= zoomList[2] && map.getZoom() < zoomList[4]) { //shades city
        stateLabel.className = 'grey-label';
        metroLabel.className = 'grey-label';
        cityLabel.className = 'blue-label';
        addressLabel.className = 'grey-label';
    } else if (map.getZoom() >= zoomList[1] && map.getZoom() < zoomList[2]) { //shades metro
        stateLabel.className = 'grey-label';
        metroLabel.className = 'blue-label';
        cityLabel.className = 'grey-label';
        addressLabel.className = 'grey-label';
    } else { //shades state
        stateLabel.className = 'blue-label';
        metroLabel.className = 'grey-label';
        cityLabel.className = 'grey-label';
        addressLabel.className = 'grey-label';
    }
  });

  //get the current year as an integer
  document.getElementById('slider').addEventListener('change', function (e) {
    Year = parseInt(e.target.value);

    //use current year
    document.getElementById('Year').innerText = Year;

    //++++++++++++++++++
    //UPDATES TO BUBBLES
    //++++++++++++++++++

    //STATE updates
    map.setPaintProperty('stateCircle', 'circle-color', {
      property: 'qg' + Year,
      type: 'interval',
      default: 'rgba(0,0,0,0)',
      stops: colorList
    })

    map.setPaintProperty('stateCircle', 'circle-stroke-color', {
      property: 'qg' + Year,
      type: 'interval',
      default: 'rgba(0,0,0,0)',
      stops: strokeBlack
    })

    map.setPaintProperty('stateCircle', 'circle-radius', [
      'interpolate', ['linear'], ['zoom'],
      zoomArray[0][0], [ '+', ['/', ['number', ['get','o' + Year]], bubbleSize[0][0]], 0],
      zoomArray[0][1], [ '+', ['/', ['number', ['get','o' + Year]], bubbleSize[0][1]], 0]
    ])

    //METRO updates
    map.setPaintProperty('metroCircle', 'circle-color', {
      property: 'qg' + Year,
      type: 'interval',
      default: 'rgba(0,0,0,0)',
      stops: colorList
    })

    map.setPaintProperty('metroCircle', 'circle-stroke-color', {
      property: 'qg' + Year,
      type: 'interval',
      default: 'rgba(0,0,0,0)',
      stops: strokeBlack
    })

    map.setPaintProperty('metroCircle', 'circle-radius', [
      'interpolate', ['linear'], ['zoom'],
      zoomArray[1][0], [ '+', ['/', ['number', ['get','so' + Year]], bubbleSize[1][0]], 0],
      zoomArray[1][1], [ '+', ['/', ['number', ['get','so' + Year]], bubbleSize[1][1]], 0]
    ])
    
    //CITY updates
    map.setPaintProperty('cityCircle', 'circle-color', {
      property: 'qg' + Year,
      type: 'interval',
      default: 'rgba(0,0,0,0)',
      stops: colorList
    })

    map.setPaintProperty('cityCircle', 'circle-stroke-color', {
      property: 'qg' + Year,
      type: 'interval',
      default: 'rgba(0,0,0,0)',
      stops: strokeBlack
    })

    map.setPaintProperty('cityCircle', 'circle-radius', [
      'interpolate', ['linear'], ['zoom'],
      zoomArray[2][0], [ '+', ['/', ['number', ['get','so' + Year]], bubbleSize[2][0]], 0],
      zoomArray[2][1], [ '+', ['/', ['number', ['get','so' + Year]], bubbleSize[2][1]], 0]
    ])

    //CITY TREERING updates: LLC
    map.setPaintProperty('llcCircle', 'circle-color', {
      property: 'qg' + Year,
      type: 'interval',
      default: 'rgba(0,0,0,0)',
      stops: [
        [0, "rgba(0,0,0,0)"],
        [1, colorList[1][1]]
      ],
    })

    map.setPaintProperty('llcCircle', 'circle-stroke-color', {
      property: 'qg' + Year,
      type: 'interval',
      default: 'rgba(0,0,0,0)',
      stops: strokeBlack
    })

    map.setPaintProperty('llcCircle', 'circle-radius', [
      'interpolate', ['linear'], ['zoom'],
      zoomArray[3][0], [ '+', ['/', ['number', ['get','so' + Year]], bubbleSize[3][0]], 0],
      zoomArray[3][1], [ '+', ['/', ['number', ['get','so' + Year]], bubbleSize[3][1]], 0]
    ])

    //CITY TREERING updates: CORP
    map.setPaintProperty('corpCircle', 'circle-color', {
      property: 'qg' + Year,
      type: 'interval',
      default: 'rgba(0,0,0,0)',
      stops: [
        [0, "rgba(0,0,0,0)"],
        [1, colorList[2][1]]
      ],
    })

    map.setPaintProperty('corpCircle', 'circle-radius', [
      'interpolate', ['linear'], ['zoom'],
      zoomArray[3][0], [ '+', ['/', ['number', ['get','TCORP' + Year]], bubbleSize[3][0]], 0],
      zoomArray[3][1], [ '+', ['/', ['number', ['get','TCORP' + Year]], bubbleSize[3][1]], 0]
    ])

    //CITY TREERING updates: Delaware
    map.setPaintProperty('deCircle', 'circle-color', {
      property: 'qg' + Year,
      type: 'interval',
      default: 'rgba(0,0,0,0)',
      stops: [
        [0, "rgba(0,0,0,0)"],
        [1, colorList[3][1]]
      ],
    })

    map.setPaintProperty('deCircle', 'circle-radius', [
      'interpolate', ['linear'], ['zoom'],
      zoomArray[3][0], [ '+', ['/', ['number', ['get','TDE' + Year]], bubbleSize[3][0]], 0],
      zoomArray[3][1], [ '+', ['/', ['number', ['get','TDE' + Year]], bubbleSize[3][1]], 0]
    ])

    //CITY TREERING updates: Patent or Trademark
    map.setPaintProperty('pttmCircle', 'circle-color', {
      property: 'qg' + Year,
      type: 'interval',
      default: 'rgba(0,0,0,0)',
      stops: [
        [0, "rgba(0,0,0,0)"],
        [1, colorList[4][1]]
      ],
    })

    map.setPaintProperty('pttmCircle', 'circle-radius', [
      'interpolate', ['linear'], ['zoom'],
      zoomArray[3][0], [ '+', ['/', ['number', ['get','TPTTM' + Year]], bubbleSize[3][0]], 0],
      zoomArray[3][1], [ '+', ['/', ['number', ['get','TPTTM' + Year]], bubbleSize[3][1]], 0]
    ])

    //CITY TREERING updates: 2+ measures
    map.setPaintProperty('twoupCircle', 'circle-color', {
      property: 'qg' + Year,
      type: 'interval',
      default: 'rgba(0,0,0,0)',
      stops: [
        [0, "rgba(0,0,0,0)"],
        [1, colorList[5][1]]
      ],
    })

    map.setPaintProperty('twoupCircle', 'circle-radius', [
      'interpolate', ['linear'], ['zoom'],
      zoomArray[3][0], [ '+', ['/', ['number', ['get','TTWOUP' + Year]], bubbleSize[3][0]], 0],
      zoomArray[3][1], [ '+', ['/', ['number', ['get','TTWOUP' + Year]], bubbleSize[3][1]], 0]
    ])

    //address updates
    map.setPaintProperty('addressCircle', 'circle-color', {
      property: 'qg' + Year,
      type: 'interval',
      default: 'rgba(0,0,0,0)',
      stops: colorList
    })

    map.setPaintProperty('addressCircle', 'circle-radius', [
      'interpolate', ['linear'], ['zoom'],
      zoomArray[4][0], [ '+', ['/', ['number', ['get','o' + Year]], bubbleSize[4][0]], 2],
      zoomArray[4][1], [ '+', ['/', ['number', ['get','o' + Year]], bubbleSize[4][1]], 2]
    ])

    map.setPaintProperty('addressCircle', 'circle-stroke-color', {
      property: 'qg' + Year,
      type: 'interval',
      default: 'rgba(0,0,0,0)',
      stops: strokeBlack
    })

    //CONTEXT Shading
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

  //++++++++++++
  //TOOLTIPS
  //++++++++++++
  // When a click event occurs near a place, open a popup tooltip at the
  // location of the feature, with description HTML from its properties.
  
  map.on('click', function (e) {
    if (map.getZoom() >= zoomList[2] && map.getZoom() < zoomList[3]) { //city
      var features = map.queryRenderedFeatures(e.point, {
        layers: ['cityCircle']
      });
    } else if (map.getZoom() >= zoomList[3] && map.getZoom() < zoomList[4]) { //metro
      var features = map.queryRenderedFeatures(e.point, {
        layers: ['llcCircle']
      });
    } else if (map.getZoom() >= zoomList[1] && map.getZoom() < zoomList[2]) { //metro
      var features = map.queryRenderedFeatures(e.point, {
        layers: ['metroCircle']
      });
    } else if (map.getZoom() < zoomList[1]) { //state
      var features = map.queryRenderedFeatures(e.point, {
        layers: ['stateCircle']
      });
    }

    if (!features.length) {
      return;
    }

    var feature = features[0];

    //displays numbers with thousands commas
    function numberWithCommas(x) {
      return x.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ",");
    }

    //designs tooltips
    if (map.getZoom() >= zoomList[2] && map.getZoom() < zoomList[3]) { //city
      var popup = new mapboxgl.Popup()
      .setLngLat(feature.geometry.coordinates)
      .setHTML('<div id="popup" class="popup" style="z-index: 10;"> ' +
          '<ul class="list-group">' +
          '<li class="list-group-item"> City: ' + feature.properties['city'] + " </li>" +
          '<li class="list-group-item"> Quality %: ' + feature.properties['qg' + Year]/10 +
          '<li class="list-group-item"> Quantity: ' + numberWithCommas(feature.properties['o' + Year]) +
          '<li class="list-group-item"> Year: ' + [Year] +
          '</ul> </div>')
          .addTo(map);
      } else if (map.getZoom() >= zoomList[3] && map.getZoom() < zoomList[4]) { //city treering
        var popup = new mapboxgl.Popup()
        .setLngLat(feature.geometry.coordinates)
        .setHTML('<div id="popup" class="popup" style="z-index: 10;"> ' +
          '<ul class="list-group">' +
          '<li class="list-group-item"> City: ' + feature.properties['city'] + " </li>" +
          '<li class="list-group-item"> Quality %: ' + feature.properties['qg' + Year]/10 +
          '<li class="list-group-item"> Quantity: ' + numberWithCommas(feature.properties['o' + Year]) +
          '<li class="list-group-item"> Year: ' + [Year] + 
          '<li class="list-group-item"> LLC: ' + numberWithCommas(feature.properties['LLC' + Year]) +
          '<li class="list-group-item"> Corp: ' + numberWithCommas(feature.properties['CORP' + Year]) +
          '<li class="list-group-item"> Delaware: ' + numberWithCommas(feature.properties['DE' + Year]) +
          '<li class="list-group-item"> Patent or TM: ' + numberWithCommas(feature.properties['PTTM' + Year]) +
          '<li class="list-group-item"> 2+ Measures: ' + numberWithCommas(feature.properties['TWOUP' + Year]) +
          '</ul> </div>')
          .addTo(map);
      } else if (map.getZoom() >= zoomList[1] && map.getZoom() < zoomList[2]) { //metro
        var popup = new mapboxgl.Popup()
        .setLngLat(feature.geometry.coordinates)
        .setHTML('<div id="popup" class="popup" style="z-index: 10;"> ' +
          '<ul class="list-group">' +
          '<li class="list-group-item"> Metro: ' + feature.properties['area'] + " </li>" +
          '<li class="list-group-item"> Quality %: ' + feature.properties['qg' + Year]/10 +
          '<li class="list-group-item"> Quantity: ' + numberWithCommas(feature.properties['o' + Year]) +
          '<li class="list-group-item"> Year: ' + [Year] +
          '</ul> </div>')
          .addTo(map);
      } else if (map.getZoom() < zoomList[1]) { //state
        var popup = new mapboxgl.Popup()
        .setLngLat(feature.geometry.coordinates)
        .setHTML('<div id="popup" class="popup" style="z-index: 10;"> ' +
          '<ul class="list-group">' +
          '<li class="list-group-item"> State: ' + feature.properties['datastate'] + " </li>" +
          '<li class="list-group-item"> Quality %: ' + feature.properties['qg' + Year]/10 +
          '<li class="list-group-item"> Quantity: ' + numberWithCommas(feature.properties['o' + Year]) +
          '<li class="list-group-item"> Year: ' + [Year] +
          '</ul> </div>')
          .addTo(map);
      }
  });

  // Use the same approach as above to indicate that the symbols are clickable
  // by changing the cursor style to 'pointer'.
  map.on('mousemove', function (e) {
    if (map.getZoom() >= zoomList[2] && map.getZoom() < zoomList[3]) { //city
      var features = map.queryRenderedFeatures(e.point, {
        layers: ['cityCircle']
      });
      map.getCanvas().style.cursor = (features.length) ? 'pointer' : '';
    } else if (map.getZoom() >= zoomList[3] && map.getZoom() < zoomList[4]) { //city treering
      var features = map.queryRenderedFeatures(e.point, {
        layers: ['llcCircle']
      });
      map.getCanvas().style.cursor = (features.length) ? 'pointer' : '';
    } else if (map.getZoom() >= zoomList[1] && map.getZoom() < zoomList[2]) { //metro
      var features = map.queryRenderedFeatures(e.point, {
        layers: ['metroCircle']
      });
      map.getCanvas().style.cursor = (features.length) ? 'pointer' : '';
    } else if (map.getZoom() < zoomList[1]) { //state
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