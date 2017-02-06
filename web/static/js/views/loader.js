import MainView from './main-view';
import RoomIndexView from './room/index';
import PlayerShowView from './player/show';
import PrivateRoomNewView from './private-room/new';

const views = {
  RoomIndexView,
  PlayerShowView,
  PrivateRoomNewView,
};

export default function loadView(viewName) {
  return views[viewName] || MainView;
}