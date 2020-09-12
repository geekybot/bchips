
import React from "react";

// reactstrap components
import {
  Button,
  Badge,
  Card,
  CardHeader,
  CardFooter,
  DropdownMenu,
  DropdownItem,
  UncontrolledDropdown,
  DropdownToggle,
  Media,
  Pagination,
  PaginationItem,
  PaginationLink,
  Progress,
  Table,
  Container,
  Row,
  Input,
  UncontrolledTooltip
} from "reactstrap";
// core components
import Header from "components/Headers/UserHeader.js";

import datalake from "../datalake";

const Web3 = require("web3");

class Tables extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      requests : []
    }   
    this.approve = this.approve.bind(this)
  }
  approve(request) {
    console.log("request apporbed")
    const { ethereum } = window;
    
    let web3 = new Web3(window.web3.currentProvider);
    let contract = new web3.eth.Contract(datalake.abi, datalake.contract);
    (async()=>{
     await contract.methods.approveMintRequest(request.index).send({
       "from" : ethereum.selectedAddress
     })
    })()
  }

  componentDidMount() {
    // this.setState({text: ethereum.selectedAddress});

    // console.log(datalake)
    // window.web3.currentProvider
    const { ethereum } = window;
    
    let web3 = new Web3(window.web3.currentProvider);
    let contract = new web3.eth.Contract(datalake.abi, datalake.contract);
   
    (async()=>{
    let getLengthMintRequests = await contract.methods.getLengthMintRequests().call()
    let requests = []
    for(let i =0 ; i<getLengthMintRequests; i++) {
      let req = await contract.methods.getMintRequest(i).call()
       console.log(req)

      //  er.sender, er.reciever, er.fromTokenId, er.toTokenid, er.amount, er.approved
      requests.push({
        "index" : i,
        "from" : req[0],
        "token" : req[6],
        "amount" : req[1],
        "status" : req[2],
        "name" : web3.utils.hexToString(req[4]),
        "icon": web3.utils.hexToString(req[7])
       })
      }
     this.setState({requests:requests})
    })()
  }
  render() {
    return (
      <>
        <Header />
        <Container className="mt--7" fluid>
         <Row className="mt-5">
            <div className="col">
              <Card className="bg-default shadow">
                <CardHeader className="bg-transparent border-0">
                  <h3 className="text-white mb-0">Token Issuance Requests</h3>
                </CardHeader>
                <Table
                  className="align-items-center table-dark table-flush"
                  responsive
                >
                  <thead className="thead-dark">
                    <tr>
                      <th scope="col">From</th>
                      <th scope="col">Token</th>
                      <th scope="col">Amount</th>
                      <th scope="col">Status</th>
                      <th>Action</th>
                      </tr>
                  </thead>
                  <tbody>
                  {this.state.requests.map((value, index) => {
                    return (
                     
                   
                    <tr key={index}>
                  
                        <th>{value.from}</th>
                        <th>{value.name}</th>
                        <th>{value.amount}</th>
                      <td>
                        <Badge color="" className="badge-dot mr-4">
                        {(value.status ? "Approved": "Pending")}
                        </Badge>
                      </td>
                      <td>
                      {(!value.status ? 
                      <Button
                        color="primary"
                        onClick={() => this.approve(value)}
                        size="sm"
                        
                      >
                        Approve
                      </Button>
                      
                      : "")}
                      
                      </td>
                     </tr>
                   ) })}
                   </tbody>
                </Table>
              </Card>
            </div>
          </Row>
        </Container>
      </>
    );
  }
}

export default Tables;
