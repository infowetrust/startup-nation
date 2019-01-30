//Mapbox Studio Public Access tokens:

//startupcarto
mapboxgl.accessToken =
  'pk.eyJ1Ijoic3RhcnR1cGNhcnRvIiwiYSI6ImNqN204cHllbDE1c3czNGxhdndpcGI5NjMifQ.zUztT384kQartYPh21LWxQ';

// Set bounds to Kentucky (with a big buffer)
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
  
  style: 'mapbox://styles/startupcarto/cjrdwob723lhr2tmqwm09a3mk',
  attributionControl: false,
  hash: true,
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
  [751, '#E97262'],
  [901, '#CF2870'],
  [951, '#9F26A6'],
  [981, '#5A3BC4'],
  [991, '#452D95']
];

//sets all circle strokes to BLACK
var strokeBlack = [
  [0, "rgba(0,0,0,0)"],
  [1, '#000'],
  [999, '#000']
];

/*
// Old context colors: Blue Green Yellow
var colorBuckets = [
  "rgba(0,0,0,0)",
  '#0C64A5',
  '#5BB9CD',
  '#8ED2BE',
  '#BEE6C0',
  '#DCF1D7'
]
*/

// New context colors diverge: Blue White Green
var colorBuckets = [
  "rgba(0,0,0,0)",
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

  var Year = 2005; //global so radio button can use it

  //Tilesets from Mapbox

  //composite data: {{state,}} county, city, address
  map.addSource('composite_data', { //name
    type: 'vector',

    //tileset keys from startupcarto's Mapbox account
    url: 'mapbox://startupcarto.90t7up0t,startupcarto.bbphij92,startupcarto.8r1dzrwh' //city, address, county
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

  // CITY BUBBLES
  map.addLayer({
    'id': 'cityCircle',
    'type': 'circle',
    'source': 'composite_data',
    'source-layer': 'ky_citygeojson',
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
        6, [ '+', ['/', ['number', ['get','so' + Year]], 5], 2],
        10, [ '+', ['/', ['number', ['get','so' + Year]], 0.5], 2]
      ],
      //quickly transition between city and address layers
      'circle-opacity': [
        'interpolate', ['linear'], ['zoom'],
        10, ['number', 0.9],
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
        3.6, ['number', 0.0],
        3.7, ['number', 0.15],
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
    'source-layer': 'ky_addressgeojson',

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
        10.1, ['number', 0.9]
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
  var zoomThreshold = 10.05;

  map.on('zoom', function() {
    if (map.getZoom() > zoomThreshold) {
        cityLabel.className = 'gray-label';
        addressLabel.className = 'blue-label';
    } else {
        cityLabel.className = 'blue-label';
        addressLabel.className = 'gray-label';
    }
  });

  //get the current year as an integer
  document.getElementById('slider').addEventListener('change', function (e) {
    Year = parseInt(e.target.value);

    //use current year
    document.getElementById('Year').innerText = Year;

    //state updates (deleted)

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
      var features = map.queryRenderedFeatures(e.point, {
        layers: ['cityCircle']
      });

      if (!features.length) {
        return;
      }

      var feature = features[0];

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
    });


  // Use the same approach as above to indicate that the symbols are clickable
  // by changing the cursor style to 'pointer'.
  map.on('mousemove', function (e) {
    var features = map.queryRenderedFeatures(e.point, {
      layers: ['cityCircle']
    });
    map.getCanvas().style.cursor = (features.length) ? 'pointer' : '';
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


//hides Alaska beyond specified zoom level
//map.on('zoomend', function () {
  //if (map.getZoom() > 3.75) {
    //document.getElementById('minimap1').style.visibility = 'hidden'
  // } else {
  //   document.getElementById('minimap1').style.visibility = 'visible'
  // }    });
