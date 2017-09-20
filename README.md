# pollock

An iOS Drawing Engine

### File Format

The project files are `Libz` compressed JSON files.

Format:

```json
{
  "canvases": [{
    "_type": "canvas",
    "text": [{
      "color": {
        "name": "black",
        "green": 0,
        "red": 0,
        "blue": 0,
        "alpha": 1
      },
      "fontName": "Arial",
      "location": {
        "xOffset": 0.43625,
        "yOffset": 0.4050387596899225
      },
      "value": "Testing",
      "fontSize": 0.025,
      "version": 1,
      "textID": "39254984-AAE3-4BC2-8A31-12F55403E0AE"
    }],
    "drawings": [{
      "points": [{
        "force": 1,
        "isPredictive": false,
        "previous": {
          "xOffset": 0.178125,
          "yOffset": 0.14777131782945738
        },
        "location": {
          "xOffset": 0.178125,
          "yOffset": 0.14777131782945738
        },
        "_type": "point"
      }],
      "isCulled": false,
      "color": {
        "name": "purple",
        "green": 0,
        "red": 255,
        "blue": 255,
        "alpha": 1
      },
      "_type": "drawing",
      "tool": {
        "name": "pen",
        "version": 1,
        "lineWidth": 0.009791666984558103,
        "forceSensitivity": 1,
        "_type": "tool"
      },
      "version": 1,
      "isSmoothingEnabled": true,
      "drawingID": "F37B8934-318D-46D8-B4A7-0AB090D93749"
    }],
    "index": 0
  }],
  "header": {
    "version": 1,
    "_type": "header",
    "projectID": "96926025-20C1-42D6-A1E6-2EE646429CBC"
  },
  "_type": "project"
}
```
