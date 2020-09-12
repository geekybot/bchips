
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
  UncontrolledTooltip
} from "reactstrap";
// core components
import Header from "components/Headers/UserHeader.js";

class Tables extends React.Component {
  render() {
    return (
      <>
        <Header />
        <Container className="mt--7" fluid>
         <Row className="mt-5">
            <div className="col">
              <Card className="bg-default shadow">
                <CardHeader className="bg-transparent border-0">
                  <h3 className="text-white mb-0">Assets List</h3>
                </CardHeader>
                <Table
                  className="align-items-center table-dark table-flush"
                  responsive
                >
                  <thead className="thead-dark">
                    <tr>
                      <th scope="col">Address</th>
                      <th scope="col">Blacklist</th>
                      <th scope="col">Action</th>
                     </tr>
                  </thead>
                  <tbody>
                    <tr>
                      <th scope="row">
                        <Media className="align-items-center">
                        
                          <Media>
                            <span className="mb-0 text-sm">
                            0x451c9EA7b62e0D29e70deD4a3f4b4C147F786507
                            </span>
                          </Media>
                        </Media>
                      </th>
                      <td>Blacklisted</td>
                      <td>
                        <Badge color="" className="badge-dot mr-4">
                        <Button
                                              color="primary"
                                              // onClick={this.approve(value)}
                                              size="sm"
                                              
                                            >
                                              Whitelist
                                            </Button>
                        </Badge>
                      </td>
                    
                     </tr>
                    <tr>
                      <th scope="row">
                        <Media className="align-items-center">
                          
                          <Media>
                            <span className="mb-0 text-sm">
                            0x7565b88bd7e691c1edf8a402291595464e9ecb33
                            </span>
                          </Media>
                        </Media>
                      </th>
                      <td>Blacklisted</td>
                      <td>
                      <Button
                                              color="primary"
                                              // onClick={this.approve(value)}
                                              size="sm"
                                              
                                            >
                                              Whitelist
                                            </Button>
                      </td>
                   
                     </tr>
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
