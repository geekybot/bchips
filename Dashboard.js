
import React from "react";
import Chart from "react-google-charts";

// reactstrap components
import {
  Button,
  Card,
  CardHeader,
  CardBody,
  FormGroup,
  Form,
  Input,
  Container,
  Row,
  Col
} from "reactstrap";
// core components
import UserHeader from "components/Headers/UserHeader.js";


let uri = {
  "name": "NY Tokens",
  "description": "NY times tokens.",
  "localization": {
    "uri": "ipfs://QmWS1VAdMD353A6SDk9wNyvkT14kyCiZrNDYAad4w1tKqT/{locale}.json",
    "default": "en",
    "locales": ["en", "es", "fr"]
  }
}

class Profile extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      name: "NY Times Token",
      symbol : "NYT"
    }
    this.onChangeName = this.onChangeName.bind(this) 
    this.onChangeSymbol = this.onChangeSymbol.bind(this) 
  }
  onChangeName(value) {
    this.setState({name : value})
  }
  onChangeSymbol(value) {
    this.setState({symbol : value})
  }
  render() {
    return (
      <>
     
        <UserHeader />
           <div class="row">
       
<Chart
    width={'100'}
    height={'100'}
    chartType="LineChart"
    loader={<div class="column">Loading Chart</div>}
    data={[
      [
        { type: 'number', label: 'x' },
        { type: 'number', label: 'values' },
        { id: 'i0', type: 'number', role: 'interval' },
        { id: 'i1', type: 'number', role: 'interval' },
        { id: 'i2', type: 'number', role: 'interval' },
        { id: 'i2', type: 'number', role: 'interval' },
        { id: 'i2', type: 'number', role: 'interval' },
        { id: 'i2', type: 'number', role: 'interval' },
      ],
      [1, 100, 90, 110, 85, 96, 104, 120],
      [2, 120, 95, 130, 90, 113, 124, 140],
      [3, 130, 105, 140, 100, 117, 133, 139],
      [4, 90, 85, 95, 85, 88, 92, 95],
      [5, 70, 74, 63, 67, 69, 70, 72],
      [6, 30, 39, 22, 21, 28, 34, 40],
      [7, 80, 77, 83, 70, 77, 85, 90],
      [8, 100, 90, 110, 85, 95, 102, 110],
    ]}
    options={{
      intervals: { style: 'sticks' },
      legend: 'none',
    }}
  />
<Chart
    width={'100'}
    height={'100'}
    chartType="ColumnChart"
    loader={<div class="column">Loading Chart</div>}
    data={[
      ['City', '2020 Population', '2010 Population'],
      ['Raipur, RPR', 8175000, 8008000],
      ['Bilaspur, BSP', 3792000, 3694000],
      ['Durg, DRG', 2695000, 2896000],
    ]}
    options={{
      title: 'Population of Largest Chhattisgarh Cities',
      chartArea: { width: '30%' },
      hAxis: {
        title: 'Total Population',
        minValue: 0,
      },
      vAxis: {
        title: 'City',
      },
    }}
    legendToggle
  />
</div>


      
      </>
    );
  }
}

export default Profile;
